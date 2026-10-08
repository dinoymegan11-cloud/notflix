<?php
declare(strict_types=1);
require_once __DIR__ . '/includes/bootstrap.php';

$rawSlug = $_GET['slug'] ?? '';
$slug = is_string($rawSlug) ? trim($rawSlug) : '';
if ($slug === '' || strlen($slug) > 180) {
    http_response_code(404);
    exit('Title not found.');
}

try {
    $pdo = database();
    $statement = $pdo->prepare("SELECT m.*,
      (SELECT GROUP_CONCAT(g.name ORDER BY g.name SEPARATOR ' · ')
       FROM movie_genres mg JOIN genres g ON g.id = mg.genre_id WHERE mg.movie_id = m.id) AS genre_names
      FROM movies m WHERE m.slug = :slug AND m.is_published = 1 LIMIT 1");
    $statement->execute(['slug' => $slug]);
    $movie = $statement->fetch();
} catch (PDOException $exception) {
    error_log('NOTFLIX title lookup failed: ' . $exception->getMessage());
    http_response_code(503);
    exit('The catalog is unavailable. Start MySQL and import database/schema.sql.');
}

if ($movie === false) {
    http_response_code(404);
    exit('Title not found.');
}

$relatedQuery = $pdo->prepare("SELECT DISTINCT m.*,
    (SELECT GROUP_CONCAT(g.name ORDER BY g.name SEPARATOR ' · ')
     FROM movie_genres mg2 JOIN genres g ON g.id = mg2.genre_id WHERE mg2.movie_id = m.id) AS genre_names
  FROM movies m
  JOIN movie_genres related_mg ON related_mg.movie_id = m.id
  WHERE related_mg.genre_id IN (SELECT genre_id FROM movie_genres WHERE movie_id = :movie_id)
    AND m.id <> :exclude_id AND m.is_published = 1
  ORDER BY m.external_rating DESC LIMIT 4");
$relatedQuery->execute(['movie_id' => $movie['id'], 'exclude_id' => $movie['id']]);
$relatedMovies = $relatedQuery->fetchAll();

$user = current_user();
$isSaved = false;
$savedIds = [];
if ($user !== null) {
    $savedQuery = $pdo->prepare('SELECT movie_id FROM watchlist WHERE user_id = :user_id');
    $savedQuery->execute(['user_id' => $user['id']]);
    $savedIds = array_map('intval', $savedQuery->fetchAll(PDO::FETCH_COLUMN));
    $isSaved = in_array((int) $movie['id'], $savedIds, true);
}

$poster = (string) ($movie['poster_url'] ?? '');
if ($poster !== '' && !str_starts_with($poster, 'http')) {
    $poster = 'https://image.tmdb.org/t/p/w780/' . ltrim($poster, '/');
}
$pageTitle = $movie['title'];
require __DIR__ . '/includes/header.php';
?>
<section class="title-detail">
  <a class="back-link" href="index.php">← Back to discover</a>
  <div class="detail-layout">
    <div class="detail-poster"><?php if ($poster !== ''): ?><img src="<?= escape($poster) ?>" alt="<?= escape($movie['title']) ?> poster"><?php endif; ?></div>
    <div class="detail-copy">
      <p class="eyebrow"><?= escape($movie['genre_names'] ?? '') ?></p>
      <h1><?= escape($movie['title']) ?></h1>
      <div class="detail-meta"><span><?= (int) $movie['release_year'] ?></span><span><?= escape($movie['age_rating'] ?: strtoupper($movie['content_type'])) ?></span><span><?= $movie['runtime_minutes'] ? (int) $movie['runtime_minutes'] . ' min' : 'Series' ?></span><span class="detail-rating">★ <?= escape((string) $movie['external_rating']) ?></span></div>
      <p class="detail-overview"><?= escape($movie['overview']) ?></p>
      <div class="detail-actions">
        <?php if ($user !== null): ?>
          <form action="index.php" method="post">
            <?= csrf_field() ?>
            <input type="hidden" name="action" value="toggle-watchlist">
            <input type="hidden" name="movie_id" value="<?= (int) $movie['id'] ?>">
            <button class="button button-primary" type="submit"><?= $isSaved ? '✓ In My List' : '+ Add to My List' ?></button>
          </form>
        <?php else: ?>
          <a class="button button-primary" href="login.php">Sign in to save</a>
        <?php endif; ?>
      </div>
      <div class="detail-note"><span>CATALOG ENTRY</span><span>Playback availability is not included in this student catalog.</span></div>
    </div>
  </div>
</section>
<?php if ($relatedMovies !== []): ?>
  <section class="collection">
    <div class="collection-head"><div><p class="collection-index">RELATED TITLES</p><h2>More to explore</h2></div></div>
    <div class="catalog-grid">
      <?php $returnView = ''; foreach ($relatedMovies as $index => $movie): require __DIR__ . '/includes/movie-card.php'; endforeach; ?>
    </div>
  </section>
<?php endif; ?>
<?php require __DIR__ . '/includes/footer.php'; ?>
