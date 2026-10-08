<?php
$cardSaved = isset($savedIds) && in_array((int) $movie['id'], $savedIds, true);
$poster = (string) ($movie['poster_url'] ?? '');
if ($poster !== '' && !str_starts_with($poster, 'http')) {
    $poster = 'https://image.tmdb.org/t/p/w500/' . ltrim($poster, '/');
}
$genres = (string) ($movie['genre_names'] ?? '');
?>
<article class="catalog-card">
  <a class="poster-link" href="title.php?slug=<?= rawurlencode($movie['slug']) ?>" aria-label="View <?= escape($movie['title']) ?>">
    <?php if ($poster !== ''): ?>
      <img class="poster-image" src="<?= escape($poster) ?>" alt="<?= escape($movie['title']) ?> poster" loading="lazy">
    <?php else: ?>
      <span class="poster-fallback"><?= escape($movie['title']) ?></span>
    <?php endif; ?>
    <span class="poster-type"><?= $movie['content_type'] === 'series' ? 'SERIES' : 'FILM' ?></span>
  </a>
  <div class="catalog-card-info">
    <div class="card-title-line">
      <h3><a href="title.php?slug=<?= rawurlencode($movie['slug']) ?>"><?= escape($movie['title']) ?></a></h3>
      <span class="card-rating">★ <?= escape((string) $movie['external_rating']) ?></span>
    </div>
    <p class="card-meta"><?= (int) $movie['release_year'] ?> <span>·</span> <?= escape($movie['age_rating'] ?: strtoupper($movie['content_type'])) ?></p>
    <p class="card-genres"><?= escape($genres) ?></p>
    <form action="index.php" method="post" class="card-list-form">
      <?= csrf_field() ?>
      <input type="hidden" name="action" value="toggle-watchlist">
      <input type="hidden" name="movie_id" value="<?= (int) $movie['id'] ?>">
      <input type="hidden" name="return_view" value="<?= escape($returnView ?? '') ?>">
      <button class="card-list-button<?= $cardSaved ? ' is-saved' : '' ?>" type="submit">
        <?= $cardSaved ? '✓ In My List' : '+ Add to My List' ?>
      </button>
    </form>
  </div>
</article>
