# NOTFLIX

NOTFLIX is a PHP and MySQL movie/series discovery catalog for XAMPP. It is an independent editorial-style design, not a copy of another streaming service.

## Run locally with XAMPP

1. Start **Apache** and **MySQL** in the XAMPP Control Panel.
2. Open phpMyAdmin at `http://localhost/phpmyadmin`.
3. Import [`database/schema.sql`](database/schema.sql). It creates the `notflix_db` database, its relational tables, and 22 sample catalog titles.
4. Open `http://localhost/xampp/Notflix/`.

The default local connection is `127.0.0.1:3306`, database `notflix_db`, username `root`, and an empty password. Override these defaults with `NOTFLIX_DB_HOST`, `NOTFLIX_DB_PORT`, `NOTFLIX_DB_NAME`, `NOTFLIX_DB_USER`, and `NOTFLIX_DB_PASSWORD` environment variables when needed.

## Included database areas

- **Accounts:** `users`, with password hashes rather than stored passwords.
- **Catalog:** `movies`, `genres`, and `movie_genres` for titles and their many-to-many genre relationships.
- **Editorial browsing:** `collections` and `collection_movies` for ordered homepage rows.
- **Personal features:** `watchlist` for each account's saved titles.
- **Ready for additional features:** `reviews`, `watch_history`, `people`, `movie_credits`, `seasons`, and `episodes`.

The last group gives the project clear opportunities to grow: add member reviews/ratings, watch progress and continue-watching, actor/director pages and cast lists, then season and episode pages for series. A separate `streaming_providers` plus `movie_availability` relationship would let the catalog show where a title is legally available without storing or redistributing video files.

## Notes

- Account creation and sign-in use PHP sessions, CSRF tokens, prepared SQL statements, and `password_hash`/`password_verify`.
- The catalog and saved lists are read from MySQL; the sample poster artwork is hosted by TMDB and TVmaze.
- The app is a discovery catalog. Playback/streaming rights and provider integrations are not included.
- For a deployed site, create a dedicated MySQL user with only the permissions the app needs instead of using XAMPP's local `root` account.
