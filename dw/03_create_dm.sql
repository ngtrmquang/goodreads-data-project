DROP SCHEMA IF EXISTS mart CASCADE;
DROP TABLE IF EXISTS mart.book_statistics;
DROP TABLE IF EXISTS mart.book_statistics;

CREATE SCHEMA mart;

CREATE TABLE mart.book_statistics (
    book_id INTEGER PRIMARY KEY,
    title VARCHAR,
    title_without_series VARCHAR,
    author_names VARCHAR[],
    num_pages INTEGER,
    average_rating FLOAT,
    ratings_count INTEGER,
    country_code VARCHAR,
    language_code VARCHAR,
    publisher VARCHAR,
    publication_year INTEGER,
    book_url VARCHAR,
    image_url VARCHAR,
    genre_1 VARCHAR,
    genre_2 VARCHAR,
    genre_3 VARCHAR,
    genre_4 VARCHAR,
    genre_5 VARCHAR,
    series_names VARCHAR[],
    original_title VARCHAR,
    original_publication_year INTEGER
);
INSERT INTO mart.book_statistics (
    book_id,
    title,
    title_without_series,
    author_names,
    num_pages,
    average_rating,
    ratings_count,
    country_code,
    language_code,
    publisher,
    publication_year,
    book_url,
    image_url,
    genre_1,
    genre_2,
    genre_3,
    genre_4,
    genre_5,
    series_names,
    original_title,
    original_publication_year
)
SELECT
    b.book_id,
    b.book_title,
    b.book_title_without_series,
    LIST(DISTINCT a.author_name ORDER BY a.author_name) AS author_names,
    b.book_num_pages,
    b.book_average_rating,
    b.book_ratings_count,
    b.book_country_code,
    b.book_language_code,
    b.book_publisher,
    b.book_publication_year,
    b.book_url,
    b.book_image_url,
    b.genre_1,
    b.genre_2,
    b.genre_3,
    b.genre_4,
    b.genre_5,
    LIST(DISTINCT s.series_title ORDER BY s.series_title) AS series_names,
    w.work_title,
    w.work_publication_year
FROM
    dim_book AS b
    LEFT JOIN bridge_book_authors AS ba
        ON b.book_id = ba.book_id
    LEFT JOIN dim_author AS a
        ON ba.author_id = a.author_id
    LEFT JOIN dim_work AS w 
        ON b.work_id = w.work_id
    LEFT JOIN bridge_book_series AS bs 
        ON b.book_id = bs.book_id
    LEFT JOIN dim_series AS s 
        ON bs.series_id = s.series_id
GROUP BY
    b.book_id,
    b.book_title,
    b.book_title_without_series,
    b.book_num_pages,
    b.book_average_rating,
    b.book_ratings_count,
    b.book_country_code,
    b.book_language_code,
    b.book_publisher,
    b.book_publication_year,
    b.book_url,
    b.book_image_url,
    b.genre_1,
    b.genre_2,
    b.genre_3,
    b.genre_4,
    b.genre_5,
    w.work_title,
    w.work_publication_year;


CREATE TABLE mart.user_ratings (
    user_id VARCHAR,
    book_id INTEGER,
    book_title VARCHAR,
    user_rating INTEGER,
    book_author_names VARCHAR[],
    book_average_rating FLOAT,
    book_publication_year INTEGER,
    book_genre_1 VARCHAR,
    book_genre_2 VARCHAR,
    book_genre_3 VARCHAR,
    book_genre_4 VARCHAR,
    book_genre_5 VARCHAR
);
INSERT INTO mart.user_ratings (
    user_id,
    book_id,
    book_title,
    user_rating,
    book_author_names,
    book_average_rating,
    book_publication_year,
    book_genre_1,
    book_genre_2,
    book_genre_3,
    book_genre_4,
    book_genre_5
)
SELECT
    i.user_id,
    i.book_id,
    w.work_title,
    i.rating,
    LIST(DISTINCT a.author_name ORDER BY a.author_name) AS book_author_names,
    b.book_average_rating,
    b.book_publication_year,
    b.genre_1,
    b.genre_2,
    b.genre_3,
    b.genre_4,
    b.genre_5
FROM
    fact_interaction AS i
    LEFT JOIN dim_book AS b
        ON i.book_id = b.book_id
    LEFT JOIN bridge_book_authors AS ba
        ON b.book_id = ba.book_id
    LEFT JOIN dim_author AS a
        ON ba.author_id = a.author_id
    LEFT JOIN dim_work AS w 
        ON b.work_id = w.work_id
GROUP BY
    i.user_id,
    i.book_id,
    w.work_title,
    i.rating,
    b.book_average_rating,
    b.book_publication_year,
    b.genre_1,
    b.genre_2,
    b.genre_3,
    b.genre_4,
    b.genre_5;