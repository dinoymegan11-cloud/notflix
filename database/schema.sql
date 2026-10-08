CREATE DATABASE IF NOT EXISTS notflix_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE notflix_db;

CREATE TABLE IF NOT EXISTS users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  display_name VARCHAR(80) NOT NULL,
  email VARCHAR(254) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('member', 'admin') NOT NULL DEFAULT 'member',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS movies (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  slug VARCHAR(180) NOT NULL,
  title VARCHAR(200) NOT NULL,
  overview TEXT NOT NULL,
  release_year SMALLINT UNSIGNED NOT NULL,
  runtime_minutes SMALLINT UNSIGNED DEFAULT NULL,
  content_type ENUM('movie', 'series') NOT NULL,
  age_rating VARCHAR(16) DEFAULT NULL,
  poster_url VARCHAR(500) DEFAULT NULL,
  backdrop_url VARCHAR(500) DEFAULT NULL,
  external_rating DECIMAL(3,1) DEFAULT NULL,
  is_featured TINYINT(1) NOT NULL DEFAULT 0,
  is_published TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_movies_slug (slug),
  KEY idx_movies_title (title),
  KEY idx_movies_year (release_year),
  KEY idx_movies_type (content_type),
  KEY idx_movies_published (is_published, release_year)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS genres (
  id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(60) NOT NULL,
  slug VARCHAR(60) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_genres_name (name),
  UNIQUE KEY uq_genres_slug (slug)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS movie_genres (
  movie_id BIGINT UNSIGNED NOT NULL,
  genre_id SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (movie_id, genre_id),
  CONSTRAINT fk_movie_genres_movie FOREIGN KEY (movie_id) REFERENCES movies (id) ON DELETE CASCADE,
  CONSTRAINT fk_movie_genres_genre FOREIGN KEY (genre_id) REFERENCES genres (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS collections (
  id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  slug VARCHAR(80) NOT NULL,
  name VARCHAR(100) NOT NULL,
  description VARCHAR(255) DEFAULT NULL,
  sort_order SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  is_published TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_collections_slug (slug)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS collection_movies (
  collection_id SMALLINT UNSIGNED NOT NULL,
  movie_id BIGINT UNSIGNED NOT NULL,
  sort_order SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (collection_id, movie_id),
  KEY idx_collection_movie_order (collection_id, sort_order),
  CONSTRAINT fk_collection_movies_collection FOREIGN KEY (collection_id) REFERENCES collections (id) ON DELETE CASCADE,
  CONSTRAINT fk_collection_movies_movie FOREIGN KEY (movie_id) REFERENCES movies (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS watchlist (
  user_id BIGINT UNSIGNED NOT NULL,
  movie_id BIGINT UNSIGNED NOT NULL,
  added_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, movie_id),
  KEY idx_watchlist_added (user_id, added_at),
  CONSTRAINT fk_watchlist_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT fk_watchlist_movie FOREIGN KEY (movie_id) REFERENCES movies (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS reviews (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  movie_id BIGINT UNSIGNED NOT NULL,
  rating TINYINT UNSIGNED NOT NULL,
  review_text TEXT DEFAULT NULL,
  status ENUM('published', 'hidden') NOT NULL DEFAULT 'published',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_review_user_movie (user_id, movie_id),
  KEY idx_reviews_movie (movie_id, status, created_at),
  CONSTRAINT chk_reviews_rating CHECK (rating BETWEEN 1 AND 10),
  CONSTRAINT fk_reviews_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT fk_reviews_movie FOREIGN KEY (movie_id) REFERENCES movies (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS watch_history (
  user_id BIGINT UNSIGNED NOT NULL,
  movie_id BIGINT UNSIGNED NOT NULL,
  progress_seconds INT UNSIGNED NOT NULL DEFAULT 0,
  completed_at DATETIME DEFAULT NULL,
  last_watched_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, movie_id),
  KEY idx_watch_history_recent (user_id, last_watched_at),
  CONSTRAINT fk_watch_history_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT fk_watch_history_movie FOREIGN KEY (movie_id) REFERENCES movies (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS people (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(160) NOT NULL,
  biography TEXT DEFAULT NULL,
  profile_url VARCHAR(500) DEFAULT NULL,
  PRIMARY KEY (id),
  KEY idx_people_name (name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS movie_credits (
  movie_id BIGINT UNSIGNED NOT NULL,
  person_id BIGINT UNSIGNED NOT NULL,
  credit_type ENUM('cast', 'director', 'writer', 'producer') NOT NULL,
  character_name VARCHAR(160) DEFAULT NULL,
  sort_order SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (movie_id, person_id, credit_type),
  CONSTRAINT fk_movie_credits_movie FOREIGN KEY (movie_id) REFERENCES movies (id) ON DELETE CASCADE,
  CONSTRAINT fk_movie_credits_person FOREIGN KEY (person_id) REFERENCES people (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS seasons (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  series_id BIGINT UNSIGNED NOT NULL,
  season_number SMALLINT UNSIGNED NOT NULL,
  title VARCHAR(200) DEFAULT NULL,
  overview TEXT DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_series_season (series_id, season_number),
  CONSTRAINT fk_seasons_series FOREIGN KEY (series_id) REFERENCES movies (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS episodes (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  season_id BIGINT UNSIGNED NOT NULL,
  episode_number SMALLINT UNSIGNED NOT NULL,
  title VARCHAR(200) NOT NULL,
  overview TEXT DEFAULT NULL,
  runtime_minutes SMALLINT UNSIGNED DEFAULT NULL,
  release_date DATE DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_season_episode (season_id, episode_number),
  CONSTRAINT fk_episodes_season FOREIGN KEY (season_id) REFERENCES seasons (id) ON DELETE CASCADE
) ENGINE=InnoDB;

INSERT IGNORE INTO genres (name, slug) VALUES
  ('Action', 'action'), ('Adventure', 'adventure'), ('Animation', 'animation'),
  ('Comedy', 'comedy'), ('Crime', 'crime'), ('Drama', 'drama'),
  ('Fantasy', 'fantasy'), ('History', 'history'), ('Mystery', 'mystery'),
  ('Romance', 'romance'), ('Science Fiction', 'sci-fi'), ('Thriller', 'thriller');

INSERT IGNORE INTO collections (slug, name, description, sort_order) VALUES
  ('trending', 'Trending now', 'Popular titles across the catalog.', 1),
  ('series', 'Popular series', 'Series worth adding to your list.', 2),
  ('movies', 'Popular films', 'Feature films for your next movie night.', 3),
  ('anime', 'Anime & animation', 'Animated stories from around the world.', 4),
  ('acclaimed', 'Critically acclaimed', 'Highly rated films and series.', 5),
  ('mystery', 'Mystery & thrillers', 'Investigations, suspense, and surprises.', 6);

INSERT IGNORE INTO movies
  (slug, title, overview, release_year, runtime_minutes, content_type, age_rating, poster_url, backdrop_url, external_rating, is_featured)
VALUES
  ('interstellar', 'Interstellar', 'When Earth becomes increasingly uninhabitable, a former pilot joins a team on a journey through a wormhole in search of a new home for humanity.', 2014, 169, 'movie', 'PG-13', 'gEU2QniE6E77NI6lCU6MxlNBvIx.jpg', 'xJHokMbljvjADYdit5fK5VQsXEG.jpg', 8.7, 1),
  ('dune-part-two', 'Dune: Part Two', 'Paul Atreides unites with Chani and the Fremen while seeking revenge against the conspirators who destroyed his family.', 2024, 166, 'movie', 'PG-13', '1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg', '1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg', 8.5, 0),
  ('stranger-things', 'Stranger Things', 'In 1980s Indiana, a group of friends encounters secret experiments and supernatural events after a young boy disappears.', 2016, NULL, 'series', 'TV-14', '49WJfeN0moxb9IPfGn8AIqMGskD.jpg', '49WJfeN0moxb9IPfGn8AIqMGskD.jpg', 8.6, 0),
  ('everything-everywhere-all-at-once', 'Everything Everywhere All at Once', 'An exhausted laundromat owner discovers she is the key to protecting the multiverse from a growing threat.', 2022, 140, 'movie', 'R-16', 'w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg', 'w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg', 7.8, 0),
  ('the-bear', 'The Bear', 'A young chef returns to Chicago to run his family''s sandwich shop and works to transform both the restaurant and its close-knit staff.', 2022, NULL, 'series', 'TV-MA', 'https://static.tvmaze.com/uploads/images/medium_portrait/629/1574642.jpg', 'https://static.tvmaze.com/uploads/images/original_untouched/629/1574642.jpg', 8.5, 0),
  ('breaking-bad', 'Breaking Bad', 'After a terminal diagnosis, chemistry teacher Walter White turns to manufacturing illegal drugs to secure his family''s future.', 2008, NULL, 'series', 'TV-MA', '3xnWaLQjelJDDF7LT1WBo6f4BRe.jpg', '3xnWaLQjelJDDF7LT1WBo6f4BRe.jpg', 9.5, 0),
  ('wednesday', 'Wednesday', 'At Nevermore Academy, Wednesday Addams investigates a series of mysterious incidents while navigating a new school.', 2022, NULL, 'series', 'TV-14', '9PFonBhy4cQy7Jz20NpMygczOkv.jpg', '9PFonBhy4cQy7Jz20NpMygczOkv.jpg', 8.0, 0),
  ('squid-game', 'Squid Game', 'People facing severe financial hardship compete in a series of children''s games for a life-changing prize.', 2021, NULL, 'series', 'TV-MA', '1QdXdRYfktUSONkl1oD5gc6Be0s.jpg', '1QdXdRYfktUSONkl1oD5gc6Be0s.jpg', 8.0, 0),
  ('the-batman', 'The Batman', 'In his second year protecting Gotham, Batman investigates a series of crimes that reveal corruption across the city.', 2022, 176, 'movie', 'PG-13', '74xTEgt7R36Fpooo50r9T25onhq.jpg', '74xTEgt7R36Fpooo50r9T25onhq.jpg', 7.8, 0),
  ('oppenheimer', 'Oppenheimer', 'The life of physicist J. Robert Oppenheimer and his role in the development of the first atomic bomb.', 2023, 181, 'movie', 'R-16', 'ptpr0kGAckfQkJeJIt8st5dglvd.jpg', 'ptpr0kGAckfQkJeJIt8st5dglvd.jpg', 8.3, 0),
  ('barbie', 'Barbie', 'After an unexpected change in Barbie Land, Barbie and Ken travel to the real world and discover a different way of life.', 2023, 114, 'movie', 'PG-13', 'iuFNMS8U5cb6xfzi51Dbkovj7vM.jpg', 'iuFNMS8U5cb6xfzi51Dbkovj7vM.jpg', 6.8, 0),
  ('poor-things', 'Poor Things', 'A young woman brought back to life by an unorthodox scientist sets out to explore the world and define her own independence.', 2023, 141, 'movie', 'R-16', 'kCGlIMHnOm8JPXq3rXM6c5wMxcT.jpg', 'kCGlIMHnOm8JPXq3rXM6c5wMxcT.jpg', 7.8, 0),
  ('arcane', 'Arcane', 'Two sisters find themselves on opposite sides of a growing conflict between the cities of Piltover and Zaun.', 2021, NULL, 'series', 'TV-14', 'fqldf2t8ztc9aiwn3k6mlX3tvRT.jpg', 'fqldf2t8ztc9aiwn3k6mlX3tvRT.jpg', 9.0, 0),
  ('spy-x-family', 'SPY x FAMILY', 'A spy, an assassin, and a telepath form a pretend family. None of them know the whole story.', 2022, NULL, 'series', 'TV-14', '3r4LYFuXrg3G8fepysr4xSLWnQL.jpg', '3r4LYFuXrg3G8fepysr4xSLWnQL.jpg', 8.2, 0),
  ('jujutsu-kaisen', 'Jujutsu Kaisen', 'A high-schooler enters the world of sorcerers after a cursed object changes his life.', 2020, NULL, 'series', 'TV-MA', 'hFWP5HkbVEe40hrXgtCeQxoccHE.jpg', 'hFWP5HkbVEe40hrXgtCeQxoccHE.jpg', 8.5, 0),
  ('the-fellowship-of-the-ring', 'The Lord of the Rings: The Fellowship of the Ring', 'A young hobbit inherits a powerful ring and joins a fellowship tasked with carrying it across Middle-earth.', 2001, 178, 'movie', 'PG-13', '6oom5QYQ2yQTMJIbnvbkBL9cHo6.jpg', '6oom5QYQ2yQTMJIbnvbkBL9cHo6.jpg', 8.9, 0),
  ('friends', 'Friends', 'Six friends in New York navigate careers, relationships, and the changing stages of adult life.', 1994, NULL, 'series', 'TV-14', '2koX1xLkpTQM4IZebYvKysFW1Nh.jpg', '2koX1xLkpTQM4IZebYvKysFW1Nh.jpg', 8.9, 0),
  ('spirited-away', 'Spirited Away', 'A girl enters a strange spirit world and must find her courage to help her family get home.', 2001, 125, 'movie', 'PG', '39wmItIWsg5sZMyRUHLkWBcuVCM.jpg', '39wmItIWsg5sZMyRUHLkWBcuVCM.jpg', 8.6, 0),
  ('inception', 'Inception', 'A skilled thief who steals secrets through shared dreams is offered a chance to erase his past by attempting an unprecedented task.', 2010, 148, 'movie', 'PG-13', 'oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg', 'oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg', 8.8, 0),
  ('the-dark-knight', 'The Dark Knight', 'Batman and Gotham''s allies face a criminal mastermind whose campaign pushes the city toward chaos.', 2008, 152, 'movie', 'PG-13', 'qJ2tW6WMUDux911r6m7haRef0WH.jpg', 'qJ2tW6WMUDux911r6m7haRef0WH.jpg', 9.0, 0),
  ('the-last-of-us', 'The Last of Us', 'Two survivors travel across a post-pandemic United States, forming a bond as they face a dangerous journey.', 2023, NULL, 'series', 'TV-MA', 'uKvVjHNqB5VmOrdxqAt2F7J78ED.jpg', 'uKvVjHNqB5VmOrdxqAt2F7J78ED.jpg', 8.7, 0),
  ('knives-out', 'Knives Out', 'A detective investigates the death of a celebrated crime novelist, questioning each member of the family.', 2019, 131, 'movie', 'PG-13', 'pThyQovXQrw2m0s9x82twj48Jq4.jpg', 'pThyQovXQrw2m0s9x82twj48Jq4.jpg', 7.9, 0);

INSERT IGNORE INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id FROM movies m JOIN genres g
  ON (m.slug = 'interstellar' AND g.slug IN ('sci-fi', 'adventure'))
  OR (m.slug = 'dune-part-two' AND g.slug IN ('sci-fi', 'adventure'))
  OR (m.slug = 'stranger-things' AND g.slug IN ('sci-fi', 'mystery'))
  OR (m.slug = 'everything-everywhere-all-at-once' AND g.slug IN ('sci-fi', 'comedy'))
  OR (m.slug = 'the-bear' AND g.slug IN ('drama', 'comedy'))
  OR (m.slug = 'breaking-bad' AND g.slug IN ('crime', 'drama'))
  OR (m.slug = 'wednesday' AND g.slug IN ('mystery', 'comedy'))
  OR (m.slug = 'squid-game' AND g.slug IN ('thriller', 'drama'))
  OR (m.slug = 'the-batman' AND g.slug IN ('crime', 'mystery'))
  OR (m.slug = 'oppenheimer' AND g.slug IN ('drama', 'history'))
  OR (m.slug = 'barbie' AND g.slug IN ('comedy', 'adventure'))
  OR (m.slug = 'poor-things' AND g.slug IN ('fantasy', 'comedy'))
  OR (m.slug = 'arcane' AND g.slug IN ('fantasy', 'action', 'animation'))
  OR (m.slug = 'spy-x-family' AND g.slug IN ('comedy', 'action', 'animation'))
  OR (m.slug = 'jujutsu-kaisen' AND g.slug IN ('fantasy', 'action', 'animation'))
  OR (m.slug = 'the-fellowship-of-the-ring' AND g.slug IN ('fantasy', 'adventure'))
  OR (m.slug = 'friends' AND g.slug IN ('comedy', 'romance'))
  OR (m.slug = 'spirited-away' AND g.slug IN ('fantasy', 'adventure', 'animation'))
  OR (m.slug = 'inception' AND g.slug IN ('sci-fi', 'thriller'))
  OR (m.slug = 'the-dark-knight' AND g.slug IN ('action', 'crime'))
  OR (m.slug = 'the-last-of-us' AND g.slug IN ('drama', 'thriller'))
  OR (m.slug = 'knives-out' AND g.slug IN ('mystery', 'comedy'));

INSERT IGNORE INTO collection_movies (collection_id, movie_id, sort_order)
SELECT c.id, m.id, CASE m.slug
  WHEN 'interstellar' THEN 1 WHEN 'dune-part-two' THEN 2 WHEN 'stranger-things' THEN 3 WHEN 'everything-everywhere-all-at-once' THEN 4
  WHEN 'the-bear' THEN 1 WHEN 'breaking-bad' THEN 2 WHEN 'wednesday' THEN 3 WHEN 'squid-game' THEN 4
  WHEN 'the-batman' THEN 1 WHEN 'oppenheimer' THEN 2 WHEN 'barbie' THEN 3 WHEN 'poor-things' THEN 4
  WHEN 'arcane' THEN 1 WHEN 'spy-x-family' THEN 2 WHEN 'jujutsu-kaisen' THEN 3
  WHEN 'the-fellowship-of-the-ring' THEN 1 WHEN 'friends' THEN 2 WHEN 'spirited-away' THEN 3
  WHEN 'inception' THEN 1 WHEN 'the-dark-knight' THEN 2 WHEN 'the-last-of-us' THEN 3 WHEN 'knives-out' THEN 4
  ELSE 50 + m.id END
FROM collections c
CROSS JOIN movies m
WHERE (c.slug = 'trending' AND m.slug IN ('interstellar', 'dune-part-two', 'stranger-things', 'everything-everywhere-all-at-once'))
   OR (c.slug = 'series' AND m.slug IN ('the-bear', 'breaking-bad', 'wednesday', 'squid-game', 'arcane', 'spy-x-family', 'jujutsu-kaisen', 'friends', 'the-last-of-us'))
   OR (c.slug = 'movies' AND m.content_type = 'movie')
   OR (c.slug = 'anime' AND m.slug IN ('arcane', 'spy-x-family', 'jujutsu-kaisen', 'spirited-away'))
   OR (c.slug = 'acclaimed' AND m.external_rating >= 8.5)
   OR (c.slug = 'mystery' AND m.slug IN ('the-batman', 'wednesday', 'inception', 'the-last-of-us', 'knives-out'));
