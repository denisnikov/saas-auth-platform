<?php
// Load environment variables
require_once 'env_loader.php';

// Initialize variables
$errors = [];
$success = '';
$logged_in = false;
$user_data = null;

// Sanitize input function
function sanitize_input($data) {
    $data = trim($data);
    $data = stripslashes($data);
    $data = htmlspecialchars($data);
    return $data;
}

// Check if user is already logged in (via session)
session_start();
if (isset($_SESSION['user_id']) && isset($_SESSION['username'])) {
    $logged_in = true;
    $user_data = [
        'id' => $_SESSION['user_id'],
        'username' => $_SESSION['username'],
        'status' => $_SESSION['status'] ?? 'inactive',
        'expiry' => $_SESSION['expiry'] ?? null
    ];
}

// Process login form submission
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['login'])) {
    $username = sanitize_input($_POST['username']);
    $password = sanitize_input($_POST['password']);

    // Validate inputs
    if (empty($username) || empty($password)) {
        $errors[] = "Username and password are required";
    }

    if (empty($errors)) {
        try {
            // Create database connection
            $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
            $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

            // Check user credentials
            $stmt = $pdo->prepare("SELECT id, username, password, status, expiry FROM users WHERE username = ?");
            $stmt->execute([$username]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($user && md5($password) === $user['password']) {
                // Login successful
                $_SESSION['user_id'] = $user['id'];
                $_SESSION['username'] = $user['username'];
                $_SESSION['status'] = $user['status'];
                $_SESSION['expiry'] = $user['expiry'];
                
                $logged_in = true;
                $user_data = $user;
                $success = "Login successful!";
            } else {
                $errors[] = "Invalid username or password";
            }
        } catch(PDOException $e) {
            $errors[] = "Database error: " . $e->getMessage();
        }
    }
}

// Process purchase form submission
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['purchase'])) {
    if (!$logged_in) {
        $errors[] = "You must be logged in to make a purchase";
    } else {
        $subscription_type = sanitize_input($_POST['subscription_type']);
        
        try {
            $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
            $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

            // Calculate new expiry date based on subscription type
            $new_status = 'active';
            $new_expiry = null;

            if ($subscription_type === 'lifetime') {
                $new_expiry = null; // Never expires
            } else {
                $months = intval($subscription_type);
                $new_expiry = date('Y-m-d', strtotime("+$months months"));
            }

            // Update user subscription in database
            $stmt = $pdo->prepare("UPDATE users SET status = ?, expiry = ? WHERE id = ?");
            $stmt->execute([$new_status, $new_expiry, $user_data['id']]);

            // Update session data
            $_SESSION['status'] = $new_status;
            $_SESSION['expiry'] = $new_expiry;
            $user_data['status'] = $new_status;
            $user_data['expiry'] = $new_expiry;

            $success = "Purchase successful! Your subscription has been updated.";
            
        } catch(PDOException $e) {
            $errors[] = "Database error: " . $e->getMessage();
        }
    }
}

// Process logout
if (isset($_GET['logout'])) {
    session_destroy();
    header("Location: login.php");
    exit();
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>User Login & Subscription</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }

        .container {
            max-width: 800px;
            margin: 0 auto;
        }

        .card {
            background: white;
            border-radius: 15px;
            box-shadow: 0 15px 35px rgba(0,0,0,0.1);
            overflow: hidden;
            margin-bottom: 20px;
        }

        .card-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }

        .card-header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }

        .card-header p {
            font-size: 1.1em;
            opacity: 0.9;
        }

        .card-body {
            padding: 40px;
        }

        .form-section {
            margin-bottom: 40px;
        }

        .section-title {
            font-size: 1.5em;
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #667eea;
        }

        .form-group {
            margin-bottom: 20px;
        }

        label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #555;
        }

        input[type="text"], input[type="password"] {
            width: 100%;
            padding: 15px;
            border: 2px solid #e1e1e1;
            border-radius: 8px;
            font-size: 16px;
            transition: border-color 0.3s;
        }

        input[type="text"]:focus, input[type="password"]:focus {
            border-color: #667eea;
            outline: none;
        }

        .btn {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            padding: 15px 30px;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.2s;
            width: 100%;
        }

        .btn:hover {
            transform: translateY(-2px);
        }

        .btn-secondary {
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
        }

        .subscription-options {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }

        .subscription-option {
            border: 2px solid #e1e1e1;
            border-radius: 10px;
            padding: 20px;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s;
        }

        .subscription-option:hover {
            border-color: #667eea;
            transform: translateY(-2px);
        }

        .subscription-option.selected {
            border-color: #667eea;
            background: #f8f9ff;
        }

        .subscription-option input[type="radio"] {
            display: none;
        }

        .subscription-title {
            font-weight: 600;
            font-size: 1.1em;
            margin-bottom: 5px;
        }

        .subscription-price {
            color: #667eea;
            font-weight: 600;
            font-size: 1.2em;
        }

        .subscription-duration {
            color: #666;
            font-size: 0.9em;
        }

        .user-info {
            background: #f8f9ff;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
        }

        .user-info h3 {
            color: #333;
            margin-bottom: 10px;
        }

        .user-details {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
        }

        .user-detail {
            padding: 10px;
        }

        .user-detail label {
            font-weight: 600;
            color: #666;
            margin-bottom: 5px;
        }

        .user-detail span {
            color: #333;
            font-weight: 500;
        }

        .status-active {
            color: #28a745;
            font-weight: 600;
        }

        .status-inactive {
            color: #dc3545;
            font-weight: 600;
        }

        .error {
            background: #f8d7da;
            color: #721c24;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            border: 1px solid #f5c6cb;
        }

        .success {
            background: #d4edda;
            color: #155724;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            border: 1px solid #c3e6cb;
        }

        .hidden {
            display: none;
        }

        .download-section {
            text-align: center;
            padding: 30px;
            background: #f8f9ff;
            border-radius: 10px;
        }

        .download-btn {
            background: linear-gradient(135deg, #28a745 0%, #20c997 100%);
            color: white;
            text-decoration: none;
            padding: 15px 40px;
            border-radius: 8px;
            font-size: 18px;
            font-weight: 600;
            display: inline-block;
            transition: transform 0.2s;
        }

        .download-btn:hover {
            transform: translateY(-2px);
        }

        .download-btn:disabled {
            background: #6c757d;
            cursor: not-allowed;
            transform: none;
        }

        .logout-link {
            text-align: center;
            margin-top: 20px;
        }

        .logout-link a {
            color: #667eea;
            text-decoration: none;
        }

        .logout-link a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="card-header">
                <h1>🔐 Software Authentication</h1>
                <p>Login to access your subscription and download the software</p>
            </div>

            <div class="card-body">
                <?php if (!empty($errors)): ?>
                    <div class="error">
                        <?php foreach ($errors as $error): ?>
                            <p><?php echo $error; ?></p>
                        <?php endforeach; ?>
                    </div>
                <?php endif; ?>

                <?php if ($success): ?>
                    <div class="success">
                        <p><?php echo $success; ?></p>
                    </div>
                <?php endif; ?>

                <!-- Login Form -->
                <div class="form-section" id="loginSection" <?php echo $logged_in ? 'style="display: none;"' : ''; ?>>
                    <h2 class="section-title">Login</h2>
                    <form method="POST" action="">
                        <div class="form-group">
                            <label for="username">Username:</label>
                            <input type="text" id="username" name="username" required 
                                   value="<?php echo isset($username) ? htmlspecialchars($username) : ''; ?>"
                                   placeholder="Enter your username">
                        </div>

                        <div class="form-group">
                            <label for="password">Password:</label>
                            <input type="password" id="password" name="password" required 
                                   placeholder="Enter your password">
                        </div>

                        <button type="submit" name="login" class="btn">Login</button>
                    </form>
                </div>

                <!-- User Info and Purchase Section -->
                <?php if ($logged_in): ?>
                    <div class="user-info">
                        <h3>👤 Welcome, <?php echo htmlspecialchars($user_data['username']); ?>!</h3>
                        <div class="user-details">
                            <div class="user-detail">
                                <label>Subscription Status:</label>
                                <span class="<?php echo $user_data['status'] === 'active' ? 'status-active' : 'status-inactive'; ?>">
                                    <?php echo strtoupper($user_data['status']); ?>
                                </span>
                            </div>
                            <div class="user-detail">
                                <label>Expiry Date:</label>
                                <span>
                                    <?php 
                                    if ($user_data['expiry']) {
                                        echo date('F j, Y', strtotime($user_data['expiry']));
                                    } else {
                                        echo 'Never (Lifetime)';
                                    }
                                    ?>
                                </span>
                            </div>
                        </div>
                    </div>

                    <!-- Purchase Section -->
                    <div class="form-section">
                        <h2 class="section-title">💳 Purchase Subscription</h2>
                        <form method="POST" action="" id="purchaseForm">
                            <div class="subscription-options">
                                <label class="subscription-option">
                                    <input type="radio" name="subscription_type" value="1" required>
                                    <div class="subscription-title">1 Month</div>
                                    <div class="subscription-price">$10</div>
                                    <div class="subscription-duration">30 days access</div>
                                </label>

                                <label class="subscription-option">
                                    <input type="radio" name="subscription_type" value="2">
                                    <div class="subscription-title">2 Months</div>
                                    <div class="subscription-price">$20</div>
                                    <div class="subscription-duration">60 days access</div>
                                </label>

                                <label class="subscription-option">
                                    <input type="radio" name="subscription_type" value="3">
                                    <div class="subscription-title">3 Months</div>
                                    <div class="subscription-price">$30</div>
                                    <div class="subscription-duration">90 days access</div>
                                </label>

                                <label class="subscription-option">
                                    <input type="radio" name="subscription_type" value="4">
                                    <div class="subscription-title">4 Months</div>
                                    <div class="subscription-price">$40</div>
                                    <div class="subscription-duration">120 days access</div>
                                </label>

                                <label class="subscription-option">
                                    <input type="radio" name="subscription_type" value="lifetime">
                                    <div class="subscription-title">Lifetime</div>
                                    <div class="subscription-price">$50</div>
                                    <div class="subscription-duration">Never expires</div>
                                </label>
                            </div>

                            <button type="submit" name="purchase" class="btn">Purchase Subscription</button>
                        </form>
                    </div>

                    <!-- Download Section -->
                    <div class="download-section">
                        <h2 class="section-title">📥 Download Software</h2>
                        <p style="margin-bottom: 20px; color: #666;">
                            Download the authentication client software to use on your computer.
                        </p>
                        
                        <?php if ($user_data['status'] === 'active'): ?>
                            <a href="/software_client.py" class="download-btn" download>
                                ⬇️ Download Software Client
                            </a>
                            <p style="margin-top: 15px; color: #666; font-size: 0.9em;">
                                File: software_client.py (Python script)
                            </p>
                        <?php else: ?>
                            <button class="download-btn" disabled>
                                ⬇️ Download Software (Requires Active Subscription)
                            </button>
                            <p style="margin-top: 15px; color: #dc3545;">
                                Please purchase a subscription to download the software.
                            </p>
                        <?php endif; ?>
                    </div>

                    <div class="logout-link">
                        <a href="?logout=true">🚪 Logout</a>
                    </div>
                <?php endif; ?>
            </div>
        </div>
    </div>

    <script>
        // Add interactivity to subscription options
        document.addEventListener('DOMContentLoaded', function() {
            const subscriptionOptions = document.querySelectorAll('.subscription-option');
            
            subscriptionOptions.forEach(option => {
                option.addEventListener('click', function() {
                    // Remove selected class from all options
                    subscriptionOptions.forEach(opt => opt.classList.remove('selected'));
                    
                    // Add selected class to clicked option
                    this.classList.add('selected');
                    
                    // Check the radio button
                    const radio = this.querySelector('input[type="radio"]');
                    radio.checked = true;
                });
            });

            // Check if any subscription is already selected (after form submission with errors)
            const checkedRadio = document.querySelector('input[name="subscription_type"]:checked');
            if (checkedRadio) {
                checkedRadio.parentElement.classList.add('selected');
            }
        });
    </script>
</body>
</html>
