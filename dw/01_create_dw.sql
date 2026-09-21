PRAGMA enable_progress_bar;
PRAGMA enable_checkpoint_on_shutdown;


DROP TABLE IF EXISTS dim_book;
DROP TABLE IF EXISTS dim_work;
DROP TABLE IF EXISTS dim_author;
DROP TABLE IF EXISTS dim_series;
DROP TABLE IF EXISTS fact_interaction;
DROP TABLE IF EXISTS dim_genre;
DROP TABLE IF EXISTS bridge_book_authors;
DROP TABLE IF EXISTS bridge_book_series;
DROP TABLE IF EXISTS bridge_book_genre;

CREATE TABLE dim_work (
    work_id INTEGER PRIMARY KEY,
    work_title VARCHAR,
    work_books_count INTEGER,
    work_publication_year INTEGER,
    work_best_book_id INTEGER,
    work_ratings_count INTEGER,
    work_ratings_sum INTEGER
);

CREATE TABLE dim_book (
    book_id INTEGER PRIMARY KEY,
    book_title VARCHAR,
    book_title_without_series VARCHAR,
    book_country_code VARCHAR,
    book_language_code VARCHAR,
    book_average_rating FLOAT,
    book_ratings_count INTEGER,
    book_format VARCHAR,
    book_publisher VARCHAR,
    book_num_pages INTEGER,
    book_publication_year INTEGER,
    book_url VARCHAR,
    book_image_url VARCHAR,
    genre_1 VARCHAR,
    genre_2 VARCHAR,
    genre_3 VARCHAR,
    genre_4 VARCHAR,
    genre_5 VARCHAR,
    work_id INTEGER,
    FOREIGN KEY (work_id) REFERENCES dim_work(work_id)
);


CREATE TABLE dim_author (
    author_id INTEGER PRIMARY KEY,
    author_name VARCHAR,
    author_average_rating FLOAT,
    author_ratings_count INTEGER
);

CREATE TABLE dim_series (
    series_id INTEGER PRIMARY KEY,
    series_title VARCHAR,
    series_works_count INTEGER,
    series_description VARCHAR
);

CREATE TABLE fact_interaction (
    user_id VARCHAR,
    book_id INTEGER,
    rating INTEGER,
    FOREIGN KEY (book_id) REFERENCES dim_book(book_id)
);

CREATE TABLE bridge_book_authors (
    book_id INTEGER,
    author_id INTEGER,
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id) REFERENCES dim_book(book_id),
    FOREIGN KEY (author_id) REFERENCES dim_author(author_id)
);

CREATE TABLE bridge_book_series (
    book_id INTEGER,
    series_id INTEGER,
    PRIMARY KEY (book_id, series_id),
    FOREIGN KEY (book_id) REFERENCES dim_book(book_id),
    FOREIGN KEY (series_id) REFERENCES dim_series(series_id)
);


SHOW TABLES; 