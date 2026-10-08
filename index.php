<?php
declare(strict_types=1);
require_once __DIR__ . '/includes/bootstrap.php';

try {
    $pdo = database();
} catch (PDOException $exception) {
    error_log('NOTFLIX database connection failed: ' . $exception->getMessage());
    http_response_code(503);
    $pageTitle = 'Database setup required';
    require __DIR__ . '/includes/header.php';
    ?>
    <section class="setup-panel">
      <p class="eyebrow">LOCAL DATABASE SETUP</p>
      <h1>Connect the catalog</h1>
      <p>NOTFLIX could not connect to MySQL. Start Apache and MySQL in XAMPP, then import <code>database/schema.sql</code> using phpMyAdmin.</p>
      <p>Default local connection: <code>127.0.0.1</code>, database <code>notflix_db</code>, user <code>root</code>, no password.</p>
    </section>
    <?php
    require __DIR__ . '/includes/footer.php';
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['action'] ?? '') === 'toggle-watchlist') {
    require_valid_csrf();
    $user = current_user();
    if ($user === null) {
        flash('notice', 'Sign in to save titles to your list.');
        redirect('login.php');
    }

    $movieId = filter_var($_POST['movie_id'] ?? null, FILTER_VALIDATE_INT);
    if ($movieId === false || $movieId === null || $movieId < 1) {
        http_response_code(400);
        exit('Invalid title.');
    }

    $exists = $pdo->prepare('SELECT id FROM movies WHERE id = :id AND is_published = 1');
    $exists->execute(['id' => $movieId]);
    if (!$exists->fetchColumn()) {
        http_response_code(404);
        exit('Title not found.');
    }

    $delete = $pdo->prepare('DELETE FROM watchlist WHERE user_id = :user_id AND movie_id = :movie_id');
    $delete->execute(['user_id' => $user['id'], 'movie_id' => $movieId]);
    if ($delete->rowCount() === 0) {
        $insert = $pdo->prepare('INSERT INTO watchlist (user_id, movie_id) VALUES (:user_id, :movie_id)');
        $insert->execute(['user_id' => $user['id'], 'movie_id' => $movieId]);
    }

    $returnView = ($_POST['return_view'] ?? '') === 'my-list' ? '?view=my-list#my-list' : '#collections';
    redirect('index.php' . $returnView);
}

$user = current_user();
$rawQuery = $_GET['q'] ?? '';
$query = is_string($rawQuery) ? trim($rawQuery) : '';
$type = in_array($_GET['type'] ?? '', ['movie', 'series'], true) ? $_GET['type'] : '';
$view = ($_GET['view'] ?? '') === 'my-list' ? 'my-list' : 'catalog';
$rawGenre = $_GET['genre'] ?? '';
$selectedGenre = is_string($rawGenre) ? trim($rawGenre) : '';
$savedIds = [];

if ($user !== null) {
    $savedQuery = $pdo->prepare('SELECT movie_id FROM watchlist WHERE user_id = :user_id');
    $savedQuery->execute(['user_id' => $user['id']]);
    $savedIds = array_map('intval', $savedQuery->fetchAll(PDO::FETCH_COLUMN));
}

$genreFilter = " AND (:genre = '' OR EXISTS (
    SELECT 1 FROM movie_genres filter_mg
    JOIN genres filter_g ON filter_g.id = filter_mg.genre_id
    WHERE filter_mg.movie_id = m.id AND filter_g.slug = :genre_match
  ))";
$searchFilter = " AND (:q = '' OR m.title LIKE :title_q OR m.overview LIKE :overview_q
  OR EXISTS (
    SELECT 1 FROM movie_genres search_mg
    JOIN genres search_g ON search_g.id = search_mg.genre_id
    WHERE search_mg.movie_id = m.id AND search_g.name LIKE :genre_q
  ))";
$typeFilter = $type !== '' ? ' AND m.content_type = :content_type' : '';

$collectionsQuery = $pdo->query('SELECT id, slug, name, description, sort_order FROM collections WHERE is_published = 1 ORDER BY sort_order');
$collections = $collectionsQuery->fetchAll();
$collectionRows = [];
$catalogSql = "SELECT m.*,
  (SELECT GROUP_CONCAT(g.name ORDER BY g.name SEPARATOR ' · ')
   FROM movie_genres mg JOIN genres g ON g.id = mg.genre_id WHERE mg.movie_id = m.id) AS genre_names
  FROM movies m";
$catalogParams = [
    'genre' => $selectedGenre,
    'genre_match' => $selectedGenre,
    'q' => $query,
    'title_q' => '%' . $query . '%',
    'overview_q' => '%' . $query . '%',
    'genre_q' => '%' . $query . '%',
];
if ($type !== '') {
    $catalogParams['content_type'] = $type;
}

foreach ($collections as $collection) {
    $sql = $catalogSql . ' JOIN collection_movies cm ON cm.movie_id = m.id
      WHERE cm.collection_id = :collection_id AND m.is_published = 1'
      . $genreFilter . $searchFilter . $typeFilter
      . ' ORDER BY cm.sort_order, m.title';
    $statement = $pdo->prepare($sql);
    $statement->execute($catalogParams + ['collection_id' => $collection['id']]);
    $collectionRows[$collection['slug']] = $statement->fetchAll();
}

$savedMovies = [];
if ($view === 'my-list' && $user !== null) {
    $savedStatement = $pdo->prepare($catalogSql . '
      JOIN watchlist w ON w.movie_id = m.id
      WHERE w.user_id = :user_id AND m.is_published = 1
      ORDER BY w.added_at DESC');
    $savedStatement->execute(['user_id' => $user['id']]);
    $savedMovies = $savedStatement->fetchAll();
}

$genreStatement = $pdo->query('SELECT name, slug FROM genres ORDER BY name');
$genres = $genreStatement->fetchAll();
$featuredStatement = $pdo->query("SELECT m.*,
  (SELECT GROUP_CONCAT(g.name ORDER BY g.name SEPARATOR ' · ')
   FROM movie_genres mg JOIN genres g ON g.id = mg.genre_id WHERE mg.movie_id = m.id) AS genre_names
  FROM movies m WHERE m.is_featured = 1 AND m.is_published = 1 LIMIT 1");
$featured = $featuredStatement->fetch();

$pageTitle = $view === 'my-list' ? 'My List' : ($query !== '' ? 'Search results' : 'Discover films and series');
require __DIR__ . '/includes/header.php';
?>
<?php if (($notice = flash('notice')) !== null): ?>
  <div class="notice-bar"><?= escape($notice) ?></div>
<?php endif; ?>

<?php if ($view === 'my-list'): ?>
  <section class="page-intro compact-intro" id="my-list">
    <p class="eyebrow">YOUR PERSONAL LIBRARY</p>
    <h1>My List</h1>
    <p>Saved titles, ready when you are.</p>
  </section>
  <?php if ($user === null): ?>
    <section class="empty-library">
      <h2>Your list belongs to you.</h2>
      <p>Sign in to save titles and see them here on your next visit.</p>
      <a class="button button-primary" href="login.php">Sign in</a>
    </section>
  <?php elseif ($savedMovies === []): ?>
    <section class="empty-library">
      <span class="empty-mark">＋</span>
      <h2>Your list is ready when you are.</h2>
      <p>Save films and series from the catalog and they will appear here.</p>
      <a class="button button-primary" href="index.php#collections">Explore the catalog</a>
    </section>
  <?php else: ?>
    <section class="catalog-grid saved-catalog">
      <?php foreach ($savedMovies as $index => $movie): ?>
        <?php $returnView = 'my-list'; require __DIR__ . '/includes/movie-card.php'; ?>
      <?php endforeach; ?>
    </section>
  <?php endif; ?>
<?php else: ?>
  <?php if ($query === '' && $selectedGenre === '' && $type === '' && $featured): ?>
    <?php
      $backdrop = (string) ($featured['backdrop_url'] ?: $featured['poster_url']);
      if ($backdrop !== '' && !str_starts_with($backdrop, 'http')) {
          $backdrop = 'https://image.tmdb.org/t/p/original/' . ltrim($backdrop, '/');
      }
    ?>
    <section class="feature-panel">
      <div class="feature-copy">
        <p class="eyebrow"><span></span> EDITOR'S SELECTION</p>
        <p class="feature-index">01 <i></i> FEATURED TITLE</p>
        <h1><?= escape($featured['title']) ?></h1>
        <p class="feature-meta"><?= (int) $featured['release_year'] ?> <span>·</span> <?= escape($featured['age_rating'] ?: strtoupper($featured['content_type'])) ?> <span>·</span> <?= $featured['runtime_minutes'] ? (int) $featured['runtime_minutes'] . ' min' : 'Series' ?> <span>·</span> <?= escape($featured['genre_names'] ?? '') ?></p>
        <p class="feature-description"><?= escape($featured['overview']) ?></p>
        <div class="feature-actions">
          <a class="button button-primary" href="title.php?slug=<?= rawurlencode($featured['slug']) ?>">View film <span aria-hidden="true">↗</span></a>
          <?php if ($user !== null): ?>
            <form action="index.php" method="post">
              <?= csrf_field() ?>
              <input type="hidden" name="action" value="toggle-watchlist">
              <input type="hidden" name="movie_id" value="<?= (int) $featured['id'] ?>">
              <button class="button button-outline" type="submit"><?= in_array((int) $featured['id'], $savedIds, true) ? '✓ In My List' : '+ Add to My List' ?></button>
            </form>
          <?php else: ?>
            <a class="button button-outline" href="login.php">Sign in to save</a>
          <?php endif; ?>
        </div>
      </div>
      <div class="feature-art" role="img" aria-label="<?= escape($featured['title']) ?> artwork" style="background-image: url('<?= escape($backdrop) ?>')">
        <div class="feature-art-caption"><span>FEATURE NO. 001</span><span><?= escape($featured['title']) ?> · <?= (int) $featured['release_year'] ?></span></div>
      </div>
    </section>
  <?php else: ?>
    <section class="page-intro compact-intro">
      <p class="eyebrow"><?= $query !== '' ? 'CATALOG SEARCH' : 'BROWSE THE COLLECTION' ?></p>
      <h1><?= $query !== '' ? 'Search results' : ($type === 'series' ? 'Series' : ($type === 'movie' ? 'Films' : ($selectedGenre !== '' ? 'Genre collection' : 'The catalog'))) ?></h1>
      <p><?= $query !== '' ? 'Results for “' . escape($query) . '”' : 'Explore titles by format, genre, or release.' ?></p>
    </section>
  <?php endif; ?>

  <section class="browse-section" id="collections">
    <div class="section-heading">
      <div>
        <p class="eyebrow">A LITTLE OF EVERYTHING</p>
        <h2>Browse by <span>genre.</span></h2>
      </div>
      <a class="text-link" href="index.php">CLEAR FILTERS <span>↗</span></a>
    </div>
    <div class="genre-list">
      <?php foreach ($genres as $genre): ?>
        <a class="genre-chip<?= $selectedGenre === $genre['slug'] ? ' is-active' : '' ?>" href="index.php?genre=<?= rawurlencode($genre['slug']) ?>#collections"><?= escape($genre['name']) ?></a>
      <?php endforeach; ?>
    </div>
  </section>

  <?php $hasResults = false; ?>
  <?php foreach ($collections as $collection): ?>
    <?php $movies = $collectionRows[$collection['slug']] ?? []; ?>
    <?php if ($movies === []) continue; ?>
    <?php $hasResults = true; ?>
    <section class="collection" id="<?= escape($collection['slug']) ?>">
      <div class="collection-head">
        <div><p class="collection-index">COLLECTION <?= str_pad((string) $collection['sort_order'], 2, '0', STR_PAD_LEFT) ?></p><h2><?= escape($collection['name']) ?></h2></div>
        <span class="collection-count"><?= count($movies) ?> TITLES</span>
      </div>
      <div class="catalog-grid">
        <?php foreach ($movies as $index => $movie): ?>
          <?php $returnView = ''; require __DIR__ . '/includes/movie-card.php'; ?>
        <?php endforeach; ?>
      </div>
    </section>
  <?php endforeach; ?>
  <?php if (!$hasResults): ?>
    <section class="empty-library">
      <span class="empty-mark">⌕</span>
      <h2>No titles found</h2>
      <p>Try a different search term or genre.</p>
      <a class="button button-primary" href="index.php">Clear search</a>
    </section>
  <?php endif; ?>
<?php endif; ?>
<?php require __DIR__ . '/includes/footer.php'; ?>
