<?php
require_once 'db.php';

$pdo = pdo();

$job_id = $_GET['job_id'];

$sql = "SELECT * FROM t_videos WHERE job_id = :job_id ORDER BY id DESC LIMIT 1";

$stmt = $pdo->prepare($sql);
$stmt->execute([
    ':job_id' => $job_id
]);

$video = $stmt->fetch(PDO::FETCH_ASSOC);
$path = $video['video_path'];

header('Content-Type: video/mp4');
readfile($path);