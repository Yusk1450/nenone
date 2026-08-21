<?php
ini_set('display_errors', 'On');
function pdo() {
    $database_address = "localhost";            // データベースアドレス
    $database_port = "8888";				
    $database_name = "nenone";	    // データベース名
    $database_username = "root";				// データベースユーザ名
    $database_password = "root";				// データベースパスワード

    $pdo = new PDO("mysql:host=".$database_address.";port=".$database_port.";dbname=".$database_name, $database_username, $database_password);

    // 静的プレースホルダを指定する
    $pdo->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
    // エラー発生時に例外を投げる
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    return $pdo;
}
