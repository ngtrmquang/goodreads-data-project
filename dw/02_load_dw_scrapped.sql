PRAGMA enable_progress_bar; 
PRAGMA enable_checkpoint_on_shutdown;





-- temp_table -> if duplicate: select book with the most info

CREATE OR REPLACE TEMP TABLE temp_scrapped AS
SELECT DISTINCT

    CAST(bookId AS INTEGER) AS book_id,
    NULLIF(TRIM(title), '') AS book_title,
    CASE "Edition Language"
        WHEN 'English' THEN 'eng'
        WHEN 'Spanish; Castilian' THEN 'spa'
        WHEN 'Hindi' THEN 'hin'
        WHEN 'German' THEN 'ger'
        WHEN 'Dutch; Flemish' THEN 'dut'
        WHEN 'Japanese' THEN 'jpn'
        WHEN 'French' THEN 'fre'
        WHEN 'Bengali' THEN 'ben'
        WHEN 'Chinese' THEN 'chi'
        WHEN 'Italian' THEN 'ita'
        WHEN 'Hungarian' THEN 'hun'
        WHEN 'Indonesian' THEN 'ind'
        WHEN 'Filipino; Pilipino' THEN 'fil'
        WHEN 'Swedish' THEN 'swe'
        ELSE NULL
    END AS book_language_code,
    CAST(rating AS FLOAT) AS book_average_rating, 
    CAST(numberOfRatings AS INTEGER) AS book_ratings_count,
    NULLIF(TRIM(bookFormat), '') AS book_format,
    NULLIF(TRIM(publishedBy), '') AS book_publisher,
    CAST(numberOfPages AS INTEGER) AS book_num_pages,
    YEAR(strptime(publishedDate, '%B %d, %Y')) AS book_publication_year,
    NULLIF(TRIM("url"), '') AS book_url,
    NULLIF(TRIM("image"), '') AS book_image_url,

    NULLIF(TRIM("Original Title"), '') AS work_title,
    YEAR(strptime(firstPublishedDate, '%B %d, %Y')) AS work_publication_year,
    
    CAST(NULLIF(regexp_extract(authorUrl, '/show/(\d+)', 1), '') AS INTEGER) AS author_id,
    NULLIF(TRIM(authorName), '') AS author_name,
    
    NULLIF(TRIM(Series), '') AS series_title

FROM read_json('C:/Users/Quang/Documents/USTH/FundDS/dataset/2026_09_19.json');


CREATE OR REPLACE TEMP TABLE temp_books AS
SELECT *
FROM temp_scrapped
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY book_id
    ORDER BY
        (book_title IS NOT NULL) DESC,
        (author_id IS NOT NULL) DESC,
        (work_title IS NOT NULL) DESC,
        (book_average_rating IS NOT NULL) DESC,
        (book_ratings_count IS NOT NULL) DESC,
        (book_num_pages IS NOT NULL) DESC
) = 1;
DROP TABLE temp_scrapped;





-- dim_author

INSERT INTO dim_author (
    author_id,
    author_name
)
SELECT
    author_id,
    MAX(author_name) AS author_name
FROM temp_books
WHERE author_id IS NOT NULL
GROUP BY author_id
ON CONFLICT (author_id) DO UPDATE SET
    author_name = COALESCE(EXCLUDED.author_name, dim_author.author_name);





-- dim_work

CREATE OR REPLACE TEMP TABLE temp_new_works AS
SELECT
    LOWER(TRIM(work_title)) AS work_title_key,
    MIN(TRIM(work_title)) AS work_title,
    MIN(work_publication_year) AS work_publication_year
FROM temp_books
WHERE 
    work_title IS NOT NULL
    AND TRIM(work_title) <> ''
GROUP BY LOWER(TRIM(work_title));


INSERT INTO dim_work (
    work_id,
    work_title,
    work_publication_year
)
SELECT
    COALESCE((SELECT MAX(work_id) FROM dim_work), 0) + ROW_NUMBER() OVER (ORDER BY work_title_key) AS work_id,
    work_title,
    work_publication_year
FROM temp_new_works
WHERE NOT EXISTS (
    SELECT 1
    FROM dim_work
    WHERE LOWER(TRIM(dim_work.work_title)) = temp_new_works.work_title_key
);


-- map_book_work
CREATE OR REPLACE TEMP TABLE temp_book_work_map AS
SELECT
    t.book_id AS book_id,
    MIN(w.work_id) AS work_id
FROM temp_books AS t
LEFT JOIN dim_work AS w
    ON LOWER(TRIM(w.work_title)) = LOWER(TRIM(t.work_title))
WHERE t.work_title IS NOT NULL
GROUP BY t.book_id;





-- dim_book

CREATE OR REPLACE TEMP TABLE temp_book_update AS
SELECT
    t.book_id,
    t.book_average_rating,
    t.book_ratings_count,
    t.book_publication_year,
    t.book_url,
    t.book_image_url,
FROM temp_books AS t
WHERE t.book_id IS NOT NULL
    AND t.book_average_rating IS NOT NULL
    AND t.book_ratings_count IS NOT NULL;

UPDATE dim_book AS d
SET
    book_average_rating = r.book_average_rating,
    book_ratings_count = r.book_ratings_count,
    book_publication_year = r.book_publication_year,
    book_url = r.book_url,
    book_image_url = r.book_image_url,
FROM temp_book_update AS r
WHERE d.book_id = r.book_id;


INSERT INTO dim_book (
    book_id,
    book_title,
    book_language_code,
    book_average_rating,
    book_ratings_count,
    book_format,
    book_publisher,
    book_num_pages,
    book_publication_year,
    book_url,
    book_image_url,
    work_id
)
SELECT DISTINCT
    t.book_id,
    t.book_title,
    t.book_language_code,
    t.book_average_rating,
    t.book_ratings_count,
    t.book_format,
    t.book_publisher,
    t.book_num_pages,
    t.book_publication_year,
    t.book_url,
    t.book_image_url,
    m.work_id
FROM temp_books AS t
LEFT JOIN temp_book_work_map AS m
    ON m.book_id = t.book_id
WHERE t.book_id IS NOT NULL
    AND NOT EXISTS (
        SELECT 1
        FROM dim_book AS d
        WHERE d.book_id = t.book_id
);





-- bridge_book_authors

INSERT INTO bridge_book_authors (
    book_id,
    author_id
)
SELECT DISTINCT
    t.book_id,
    t.author_id
FROM temp_books AS t
WHERE 
    t.book_id IS NOT NULL 
    AND t.author_id IS NOT NULL
ON CONFLICT (book_id, author_id) DO NOTHING;





-- dim_series

CREATE OR REPLACE TEMP TABLE temp_new_series AS
SELECT
    LOWER(TRIM(series_title)) AS series_title_key,
    MIN(TRIM(series_title)) AS series_title
FROM temp_books
WHERE series_title IS NOT NULL
    AND TRIM(series_title) <> ''
GROUP BY LOWER(TRIM(series_title));


INSERT INTO dim_series (
    series_id,
    series_title
)
SELECT
    COALESCE((SELECT MAX(series_id) FROM dim_series), 0) + ROW_NUMBER() OVER (ORDER BY series_title_key) AS series_id,
    series_title
FROM temp_new_series
WHERE NOT EXISTS (
    SELECT 1
    FROM dim_series
    WHERE LOWER(TRIM(dim_series.series_title)) = temp_new_series.series_title_key
);


-- bridge_book_series
INSERT INTO bridge_book_series (
    book_id,
    series_id
)

SELECT DISTINCT
    t.book_id AS book_id,
    MIN(s.series_id) AS series_id
FROM temp_books AS t
JOIN dim_series AS s
    ON LOWER(TRIM(s.series_title)) = LOWER(TRIM(t.series_title))
WHERE 
    t.book_id IS NOT NULL
    AND t.series_title IS NOT NULL
    AND TRIM(t.series_title) <> ''
GROUP BY t.book_id
ON CONFLICT (book_id, series_id) DO NOTHING;


DROP TABLE IF EXISTS temp_new_works;
DROP TABLE IF EXISTS temp_new_series;
DROP TABLE IF EXISTS temp_book_work_map;
DROP TABLE IF EXISTS temp_books;