<?php
require_once 'db.php';

$pdo = pdo();


$job_id = $_POST['job_id'];
$files = $_FILES['image'];

$folder_name = $job_id. '_'. date('YmdHis');
$folder_path = 'uploads/'.$folder_name;
mkdir($folder_path, 0777, true);


foreach ($files['tmp_name'] as $index => $tmp_name) {
    $ext = strtolower(pathinfo($files['name'][$index], PATHINFO_EXTENSION));
    $filename = sprintf('frame_%03d.%s', $index + 1, $ext);
    move_uploaded_file($tmp_name, $folder_path.'/'.$filename);
}


exec('/opt/homebrew/bin/ffmpeg -y -framerate 3/4 -i "' . $folder_path . '/frame_%03d.' . $ext . '" -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:v libx264 -pix_fmt yuv420p "' . $folder_path . '/output.mp4" 2>&1');

$sql = "INSERT INTO t_videos (job_id, folder_path, video_path) VALUES (:job_id, :folder_path, :video_path)";
$stmt = $pdo->prepare($sql);
$stmt->execute([
    ':job_id' => $job_id,
    ':folder_path' => $folder_path,
    ':video_path' => $folder_path . '/output.mp4'
]);

echo 'ok';