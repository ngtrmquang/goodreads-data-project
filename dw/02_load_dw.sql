PRAGMA enable_progress_bar; 
PRAGMA enable_checkpoint_on_shutdown;


-- dim_work
INSERT INTO dim_work (
    work_id,
    work_title,
    work_books_count,
    work_publication_year,
    work_best_book_id,
    work_ratings_count,
    work_ratings_sum
)
SELECT 
    TRY_CAST(work_id AS INTEGER) AS work_id,
    original_title AS work_title,
    TRY_CAST(books_count AS INTEGER) AS work_books_count,
    TRY_CAST(original_publication_year AS INTEGER) AS work_publication_year,
    TRY_CAST(best_book_id AS INTEGER) AS work_best_book_id,
    TRY_CAST(ratings_count AS INTEGER) AS work_ratings_count,
    TRY_CAST(ratings_sum AS INTEGER) AS work_ratings_sum
FROM read_json('C:/Users/Quang/Documents/USTH/FundDS/dataset/goodreads_book_works.json.gz');



-- dim_author
INSERT INTO dim_author (
    author_id,
    author_name,
    author_average_rating,
    author_ratings_count
)
SELECT 
    TRY_CAST(author_id AS INTEGER) AS author_id,
    name AS author_name,
    TRY_CAST(average_rating AS FLOAT) AS author_average_rating,
    TRY_CAST(ratings_count AS INTEGER) AS author_ratings_count
FROM read_json('C:/Users/Quang/Documents/USTH/FundDS/dataset/goodreads_book_authors.json.gz');


-- dim_series
INSERT INTO dim_series (
    series_id,
    series_title,
    series_works_count,
    series_description
)
SELECT 
    TRY_CAST(series_id AS INTEGER) AS series_id,
    title AS series_title,
    TRY_CAST(series_works_count AS INTEGER) AS series_works_count,
    description AS series_description
FROM read_json('C:/Users/Quang/Documents/USTH/FundDS/dataset/goodreads_book_series.json.gz');



-- top 5 genres
WITH expanded AS (
    SELECT 
        TRY_CAST(book_id AS INTEGER) AS book_id,
        UNNEST(genres)
    FROM read_json('C:/Users/Quang/Documents/USTH/FundDS/dataset/goodreads_book_genres_initial.json.gz')
),
unpivoted AS (
    UNPIVOT expanded
    ON COLUMNS(* EXCLUDE (book_id))
    INTO
        NAME raw_genre_name
        VALUE genre_vote
),
splitted AS (
    SELECT 
        book_id,
        trim(UNNEST(string_split(raw_genre_name, ','))) AS genre_name,
        TRY_CAST(genre_vote AS INTEGER) AS genre_vote
    FROM unpivoted
    WHERE TRY_CAST(genre_vote AS INTEGER) > 0
),
aggregated AS (
    SELECT 
        book_id,
        genre_name,
        SUM(genre_vote) AS total_vote
    FROM splitted
    GROUP BY book_id, genre_name
),
ranked AS (
    SELECT 
        book_id,
        genre_name,
        ROW_NUMBER() OVER (
            PARTITION BY book_id 
            ORDER BY total_vote DESC
        ) AS rank
    FROM aggregated
),
array_genres AS (
    SELECT 
        book_id,
        LIST(genre_name) AS top_5_genres
    FROM (
        SELECT * FROM ranked 
        WHERE rank <= 5 
        ORDER BY book_id, rank
    )
    GROUP BY book_id
),
final_genres AS (
    SELECT 
        book_id,
        top_5_genres[1] AS genre_1,
        top_5_genres[2] AS genre_2,
        top_5_genres[3] AS genre_3,
        top_5_genres[4] AS genre_4,
        top_5_genres[5] AS genre_5
    FROM array_genres
)
-- dim_book
INSERT INTO dim_book (
    book_id,
    book_title,
    book_title_without_series,
    book_country_code,
    book_language_code,
    book_average_rating,
    book_ratings_count,
    book_format,
    book_publisher,
    book_num_pages,
    book_publication_year,
    book_url,
    book_image_url,
    genre_1,
    genre_2,
    genre_3,
    genre_4,
    genre_5,
    work_id
)
SELECT 
    TRY_CAST(b.book_id AS INTEGER) AS book_id,
    b.title AS book_title,
    b.title_without_series AS book_title_without_series,
    b.country_code AS book_country_code,
    b.language_code AS book_language_code,
    TRY_CAST(b.average_rating AS FLOAT) AS book_average_rating,
    TRY_CAST(b.ratings_count AS INTEGER) AS book_ratings_count,
    b.format AS book_format,
    b.publisher AS book_publisher,
    TRY_CAST(b.num_pages AS INTEGER) AS book_num_pages,
    TRY_CAST(b.publication_year AS INTEGER) AS book_publication_year,
    b.url AS book_url,
    b.image_url AS book_image_url,
    g.genre_1,
    g.genre_2,
    g.genre_3,
    g.genre_4,
    g.genre_5,
    w.work_id AS work_id
FROM read_json('C:/Users/Quang/Documents/USTH/FundDS/dataset/goodreads_books.json.gz') AS b -- $1 là đường dẫn file goodreads_books.json.gz
LEFT JOIN final_genres AS g 
    ON TRY_CAST(b.book_id AS INTEGER) = g.book_id
LEFT JOIN dim_work AS w
    ON TRY_CAST(b.work_id AS INTEGER) = w.work_id;



-- fact_interaction
INSERT INTO fact_interaction (
    user_id,
    book_id,
    rating
)
SELECT
    i.user_id AS user_id,
    TRY_CAST(i.book_id AS INTEGER) AS book_id,
    TRY_CAST(i.rating AS INTEGER) AS rating
FROM read_parquet(
    'C:/Users/Quang/Documents/USTH/FundDS/dataset/goodreads_interactions.parquet') AS i
INNER JOIN dim_book AS b
    ON TRY_CAST(i.book_id AS INTEGER) = b.book_id
LIMIT 10000000;

-- bridge_book_authors
INSERT INTO bridge_book_authors (
    book_id,
    author_id
)
SELECT DISTINCT
    TRY_CAST(book_id AS INTEGER) AS book_id,
    TRY_CAST(a.author_id AS INTEGER) AS author_id
FROM read_json('C:/Users/Quang/Documents/USTH/FundDS/dataset/goodreads_books.json.gz')
CROSS JOIN UNNEST(authors) AS temp(a);


-- bridge_book_series
INSERT INTO bridge_book_series (
    book_id,
    series_id
)
SELECT DISTINCT
    TRY_CAST(book_id AS INTEGER) AS book_id,
    TRY_CAST(s AS INTEGER) AS series_id
FROM read_json('C:/Users/Quang/Documents/USTH/FundDS/dataset/goodreads_books.json.gz')
CROSS JOIN UNNEST(series) AS temp(s);
