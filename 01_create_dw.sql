-- Step 1: DW - Create star schema tables (Data Warehouse)
-- Run this first

-- Set up initial configurations
PRAGMA enable_progress_bar;
PRAGMA enable_checkpoint_on_shutdown;


-- ============================================================
-- Drop existing tables if they exist
-- ============================================================

DROP TABLE IF EXISTS book_author_bridge;
DROP TABLE IF EXISTS book_genre_bridge;
DROP TABLE IF EXISTS fact_book;

DROP TABLE IF EXISTS dim_book;
DROP TABLE IF EXISTS dim_work;
DROP TABLE IF EXISTS dim_author;
DROP TABLE IF EXISTS dim_genre;


-- ============================================================
-- Create dim_book table
-- Grain: One row per Goodreads book / edition
-- ============================================================

CREATE TABLE dim_book (
    book_key INTEGER PRIMARY KEY,
    book_id INTEGER,

    title VARCHAR,
    title_without_series VARCHAR,

    isbn VARCHAR,
    isbn13 VARCHAR,
    asin VARCHAR,
    kindle_asin VARCHAR,

    format VARCHAR,
    edition_information VARCHAR,
    is_ebook BOOLEAN,

    series VARCHAR[],

    publisher VARCHAR,
    country_code VARCHAR,
    language_code VARCHAR,

    publication_year INTEGER,
    publication_month INTEGER,
    publication_day INTEGER,

    url VARCHAR,
    image_url VARCHAR,
    description VARCHAR
);


-- ============================================================
-- Create dim_work table
-- ============================================================

CREATE TABLE dim_work (
    work_key INTEGER PRIMARY KEY,
    work_id INTEGER,

    original_title VARCHAR,

    original_publication_year INTEGER,
    original_publication_month INTEGER,
    original_publication_day INTEGER,

    original_language_id VARCHAR,
    default_description_language_code VARCHAR,

    media_type VARCHAR,

    best_book_id INTEGER,
    default_chaptering_book_id INTEGER,

    books_count INTEGER,
    reviews_count INTEGER,
    ratings_count INTEGER,
    text_reviews_count INTEGER,
    ratings_sum INTEGER
);


-- ============================================================
-- Create dim_author table
-- ============================================================

CREATE TABLE dim_author (
    author_key INTEGER PRIMARY KEY,
    author_id INTEGER,

    name VARCHAR,

    average_rating DOUBLE,
    ratings_count INTEGER,
    text_reviews_count INTEGER
);


-- ============================================================
-- Create dim_genre table
-- ============================================================

CREATE TABLE dim_genre (
    genre_key INTEGER PRIMARY KEY,
    genre_name VARCHAR
);


-- ============================================================
-- Create fact_book table
-- Grain: One row per Goodreads book / edition
-- ============================================================

CREATE TABLE fact_book (
    book_key INTEGER PRIMARY KEY,
    work_key INTEGER,

    average_rating DOUBLE,
    ratings_count INTEGER,
    text_reviews_count INTEGER,
    num_pages INTEGER,

    FOREIGN KEY (book_key)
        REFERENCES dim_book(book_key),

    FOREIGN KEY (work_key)
        REFERENCES dim_work(work_key)
);


-- ============================================================
-- Create book_author_bridge table
-- Many-to-many: Book <-> Author
-- ============================================================

CREATE TABLE book_author_bridge (
    book_key INTEGER,
    author_key INTEGER,
    author_role VARCHAR,

    PRIMARY KEY (book_key, author_key),

    FOREIGN KEY (book_key)
        REFERENCES dim_book(book_key),

    FOREIGN KEY (author_key)
        REFERENCES dim_author(author_key)
);


-- ============================================================
-- Create book_genre_bridge table
-- Many-to-many: Book <-> Genre
-- genre_count = count associated with the genre
-- ============================================================

CREATE TABLE book_genre_bridge (
    book_key INTEGER,
    genre_key INTEGER,
    genre_count INTEGER,

    PRIMARY KEY (book_key, genre_key),

    FOREIGN KEY (book_key)
        REFERENCES dim_book(book_key),

    FOREIGN KEY (genre_key)
        REFERENCES dim_genre(genre_key)
);


-- ============================================================
-- Verify tables
-- ============================================================

SHOW TABLES;