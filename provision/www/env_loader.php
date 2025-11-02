<?php
// env_loader.php - Load environment variables from .venv file

function loadEnv($path) {
    if (!file_exists($path)) {
        throw new Exception("Environment file not found: " . $path);
    }
    
    $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        // Skip comments and empty lines
        if (strpos(trim($line), '#') === 0 || trim($line) === '') {
            continue;
        }
        
        // Split key and value
        list($name, $value) = explode('=', $line, 2);
        $name = trim($name);
        $value = trim($value);
        
        // Remove quotes if present
        $value = trim($value, '"\'');
        
        // Set environment variable if not already set
        if (!array_key_exists($name, $_ENV)) {
            putenv("$name=$value");
            $_ENV[$name] = $value;
            $_SERVER[$name] = $value;
        }
    }
}

// Load environment variables from .venv file
$envPath = '/etc/demo/.venv'; // Change this to your desired path
try {
    loadEnv($envPath);
} catch (Exception $e) {
    error_log("Environment loading warning: " . $e->getMessage());
}

// Define constants for common environment variables
define('DB_HOST', getenv('DB_HOST') ?: 'localhost');
define('DB_NAME', getenv('DB_NAME') ?: 'your_database_name');
define('DB_USER', getenv('DB_USER') ?: 'your_username');
define('DB_PASS', getenv('DB_PASS') ?: 'your_password');
define('NGROK_API_KEY', getenv('NGROK_API_KEY') ?: '');

?>
