bonjour, je m'appelle Quang.

1. terminal: duckdb goodread.duckdb

2. terminal: .read C:/Users/Quang/Documents/USTH/FundDS/dw/01_create_dw.sql

3. run statements in 02_load_dw.sql, or run the file at once if you computar is strong

4. terminal: .read C:/Users/Quang/Documents/USTH/FundDS/dw/02_load_dw_scrapped.sql

5. run statements in 03_create_dm.sql, like step 3

6. lưu math

```sql
COPY mart.book_statistics
TO 'C:\Users\Quang\Documents\USTH\FundDS\dataset\mart_book_statistics.parquet'
(
    FORMAT PARQUET,
    COMPRESSION ZSTD
);

COPY mart.user_ratings
TO 'C:\Users\Quang\Documents\USTH\FundDS\dataset\mart_user_ratings.parquet'
(
    FORMAT PARQUET,
    COMPRESSION ZSTD
);
```