-- Step 2: DW - Load data from source files into star schema tables
-- Run this after Step 1


-- ============================================================
-- 1. Load dim_book
-- ============================================================

INSERT INTO dim_book (
    book_key,
    book_id,
    title,
    title_without_series,
    isbn,
    isbn13,
    asin,
    kindle_asin,
    format,
    edition_information,
    is_ebook,
    series,
    publisher,
    country_code,
    language_code,
    publication_year,
    publication_month,
    publication_day,
    url,
    image_url,
    description
)
SELECT
    ROW_NUMBER() OVER (ORDER BY book_id) AS book_key,

    TRY_CAST(book_id AS INTEGER),

    title,
    title_without_series,

    isbn,
    isbn13,
    asin,
    kindle_asin,

    format,
    edition_information,

    TRY_CAST(is_ebook AS BOOLEAN),

    series,

    publisher,
    country_code,
    language_code,

    TRY_CAST(publication_year AS INTEGER),
    TRY_CAST(publication_month AS INTEGER),
    TRY_CAST(publication_day AS INTEGER),

    url,
    image_url,
    description

FROM read_json_auto($1);


-- ============================================================
-- 2. Load dim_work
-- ============================================================

INSERT INTO dim_work (
    work_key,
    work_id,
    original_title,
    original_publication_year,
    original_publication_month,
    original_publication_day,
    original_language_id,
    default_description_language_code,
    media_type,
    best_book_id,
    default_chaptering_book_id,
    books_count,
    reviews_count,
    ratings_count,
    text_reviews_count,
    ratings_sum
)
SELECT
    ROW_NUMBER() OVER (ORDER BY work_id) AS work_key,

    TRY_CAST(work_id AS INTEGER),

    original_title,

    TRY_CAST(original_publication_year AS INTEGER),
    TRY_CAST(original_publication_month AS INTEGER),
    TRY_CAST(original_publication_day AS INTEGER),

    original_language_id,
    default_description_language_code,

    media_type,

    TRY_CAST(best_book_id AS INTEGER),
    TRY_CAST(default_chaptering_book_id AS INTEGER),

    TRY_CAST(books_count AS INTEGER),
    TRY_CAST(reviews_count AS INTEGER),
    TRY_CAST(ratings_count AS INTEGER),
    TRY_CAST(text_reviews_count AS INTEGER),
    TRY_CAST(ratings_sum AS INTEGER)

FROM read_json_auto($2);


-- ============================================================
-- 3. Load dim_author
-- ============================================================

INSERT INTO dim_author (
    author_key,
    author_id,
    name,
    average_rating,
    ratings_count,
    text_reviews_count
)
SELECT
    ROW_NUMBER() OVER (ORDER BY author_id) AS author_key,

    TRY_CAST(author_id AS INTEGER),

    name,

    TRY_CAST(average_rating AS DOUBLE),
    TRY_CAST(ratings_count AS INTEGER),
    TRY_CAST(text_reviews_count AS INTEGER)

FROM read_json_auto($3);


-- ============================================================
-- 4. Load dim_genre
-- ============================================================

INSERT INTO dim_genre (
    genre_key,
    genre_name
)
VALUES
    (1, 'history, historical fiction, biography'),
    (2, 'fiction'),
    (3, 'fantasy, paranormal'),
    (4, 'mystery, thriller, crime'),
    (5, 'poetry'),
    (6, 'romance'),
    (7, 'non-fiction'),
    (8, 'children'),
    (9, 'young-adult'),
    (10, 'comics, graphic');


-- ============================================================
-- 5. Load fact_book
-- ============================================================

INSERT INTO fact_book (
    book_key,
    work_key,
    average_rating,
    ratings_count,
    text_reviews_count,
    num_pages
)
SELECT
    b.book_key,

    w.work_key,

    TRY_CAST(src.average_rating AS DOUBLE),
    TRY_CAST(src.ratings_count AS INTEGER),
    TRY_CAST(src.text_reviews_count AS INTEGER),
    TRY_CAST(src.num_pages AS INTEGER)

FROM read_json_auto($1) AS src

JOIN dim_book AS b
    ON b.book_id = TRY_CAST(src.book_id AS INTEGER)

LEFT JOIN dim_work AS w
    ON w.work_id = TRY_CAST(src.work_id AS INTEGER);


-- ============================================================
-- 6. Load book_author_bridge
-- ============================================================

INSERT INTO book_author_bridge (
    book_key,
    author_key,
    author_role
)
SELECT
    b.book_key,

    a.author_key,

    author.author_role

FROM read_json_auto($1) AS src

JOIN dim_book AS b
    ON b.book_id = TRY_CAST(src.book_id AS INTEGER)

CROSS JOIN UNNEST(src.authors)
    AS author(author_id, author_role)

JOIN dim_author AS a
    ON a.author_id = TRY_CAST(author.author_id AS INTEGER);


-- ============================================================
-- 7. Load book_genre_bridge
-- ============================================================

INSERT INTO book_genre_bridge (
    book_key,
    genre_key,
    genre_count
)
SELECT
    b.book_key,
    g.genre_key,

    CASE g.genre_name

        WHEN 'history, historical fiction, biography'
            THEN src.genres."history, historical fiction, biography"

        WHEN 'fiction'
            THEN src.genres.fiction

        WHEN 'fantasy, paranormal'
            THEN src.genres."fantasy, paranormal"

        WHEN 'mystery, thriller, crime'
            THEN src.genres."mystery, thriller, crime"

        WHEN 'poetry'
            THEN src.genres.poetry

        WHEN 'romance'
            THEN src.genres.romance

        WHEN 'non-fiction'
            THEN src.genres."non-fiction"

        WHEN 'children'
            THEN src.genres.children

        WHEN 'young-adult'
            THEN src.genres."young-adult"

        WHEN 'comics, graphic'
            THEN src.genres."comics, graphic"

    END AS genre_count

FROM read_json_auto($4) AS src

JOIN dim_book AS b
    ON b.book_id = TRY_CAST(src.book_id AS INTEGER)

CROSS JOIN dim_genre AS g

WHERE CASE g.genre_name

    WHEN 'history, historical fiction, biography'
        THEN src.genres."history, historical fiction, biography"

    WHEN 'fiction'
        THEN src.genres.fiction

    WHEN 'fantasy, paranormal'
        THEN src.genres."fantasy, paranormal"

    WHEN 'mystery, thriller, crime'
        THEN src.genres."mystery, thriller, crime"

    WHEN 'poetry'
        THEN src.genres.poetry

    WHEN 'romance'
        THEN src.genres.romance

    WHEN 'non-fiction'
        THEN src.genres."non-fiction"

    WHEN 'children'
        THEN src.genres.children

    WHEN 'young-adult'
        THEN src.genres."young-adult"

    WHEN 'comics, graphic'
        THEN src.genres."comics, graphic"

END IS NOT NULL;


-- ============================================================
-- 8. Verify data was loaded
-- ============================================================

SELECT 'Book Dimension' AS table_name, COUNT(*) AS record_count
FROM dim_book

UNION ALL

SELECT 'Work Dimension', COUNT(*)
FROM dim_work

UNION ALL

SELECT 'Author Dimension', COUNT(*)
FROM dim_author

UNION ALL

SELECT 'Genre Dimension', COUNT(*)
FROM dim_genre

UNION ALL

SELECT 'Book Fact', COUNT(*)
FROM fact_book

UNION ALL

SELECT 'Book Author Bridge', COUNT(*)
FROM book_author_bridge

UNION ALL

SELECT 'Book Genre Bridge', COUNT(*)
FROM book_genre_bridge;


-- ============================================================
-- 9. Referential integrity checks
-- ============================================================

SELECT '=== Referential Integrity Check ===' AS info;


SELECT
    'Orphaned work_keys in fact_book' AS check_type,
    COUNT(*) AS orphaned_count
FROM fact_book
WHERE work_key IS NOT NULL
  AND work_key NOT IN (
      SELECT work_key
      FROM dim_work
  );


SELECT
    'Orphaned book_keys in book_author_bridge' AS check_type,
    COUNT(*) AS orphaned_count
FROM book_author_bridge
WHERE book_key NOT IN (
    SELECT book_key
    FROM dim_book
);


SELECT
    'Orphaned author_keys in book_author_bridge' AS check_type,
    COUNT(*) AS orphaned_count
FROM book_author_bridge
WHERE author_key NOT IN (
    SELECT author_key
    FROM dim_author
);


SELECT
    'Orphaned book_keys in book_genre_bridge' AS check_type,
    COUNT(*) AS orphaned_count
FROM book_genre_bridge
WHERE book_key NOT IN (
    SELECT book_key
    FROM dim_book
);


SELECT
    'Orphaned genre_keys in book_genre_bridge' AS check_type,
    COUNT(*) AS orphaned_count
FROM book_genre_bridge
WHERE genre_key NOT IN (
    SELECT genre_key
    FROM dim_genre
);


-- ============================================================
-- 10. Show sample data
-- ============================================================

SELECT '=== Book Dimension Sample ===' AS info;
SELECT *
FROM dim_book
LIMIT 5;


SELECT '=== Work Dimension Sample ===' AS info;
SELECT *
FROM dim_work
LIMIT 5;


SELECT '=== Author Dimension Sample ===' AS info;
SELECT *
FROM dim_author
LIMIT 5;


SELECT '=== Genre Dimension Sample ===' AS info;
SELECT *
FROM dim_genre
LIMIT 5;


SELECT '=== Book Fact Sample ===' AS info;
SELECT *
FROM fact_book
LIMIT 5;


SELECT '=== Book Author Bridge Sample ===' AS info;
SELECT *
FROM book_author_bridge
LIMIT 5;


SELECT '=== Book Genre Bridge Sample ===' AS info;
SELECT *
FROM book_genre_bridge
LIMIT 5;