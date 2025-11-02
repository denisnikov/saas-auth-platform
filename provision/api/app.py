#!venv/bin/python3
"""
Flask Authentication API
Run with: /var/www/api/venv/bin/python3 app.py
"""

from flask import Flask, request, jsonify
import mysql.connector
from datetime import datetime, date
import os
import sys
import hashlib

# Add the current directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

app = Flask(__name__)

def load_env_file(env_path="/etc/demo/.venv"):
    """Load environment variables from .venv file"""
    env_vars = {}
    try:
        with open(env_path, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    key, value = line.split('=', 1)
                    env_vars[key.strip()] = value.strip().strip('"\'')
        return env_vars
    except FileNotFoundError:
        print(f"❌ Error: Environment file not found at {env_path}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error reading environment file: {e}")
        sys.exit(1)

def get_db_connection():
    """Create database connection using credentials from .venv file"""
    env_vars = load_env_file()
    
    try:
        connection = mysql.connector.connect(
            host=env_vars.get('DB_HOST', 'localhost'),
            database=env_vars.get('DB_NAME', 'auth_demo'),
            user=env_vars.get('DB_USER', 'auth_user'),
            password=env_vars.get('DB_PASS', ''),
            autocommit=True
        )
        return connection
    except mysql.connector.Error as e:
        print(f"❌ Database connection error: {e}")
        return None

def md5_hash(password):
    """Create MD5 hash of password"""
    return hashlib.md5(password.encode()).hexdigest()

@app.route('/authenticate', methods=['POST'])
def authenticate():
    """
    Authenticate user and check subscription status from database
    Expected JSON: {"username": "user", "password": "pass"}
    """
    try:
        data = request.get_json()
        
        print(f"🔍 Received authentication request for user: {data.get('username')}")
        
        if not data:
            return jsonify({
                'success': False,
                'message': 'No JSON data received'
            }), 400
        
        if 'username' not in data or 'password' not in data:
            return jsonify({
                'success': False,
                'message': 'Username and password required'
            }), 400
        
        username = data['username'].strip()
        password = data['password'].strip()
        
        if not username or not password:
            return jsonify({
                'success': False,
                'message': 'Username and password cannot be empty'
            }), 400
        
        # Get database connection
        conn = get_db_connection()
        if not conn:
            return jsonify({
                'success': False,
                'message': 'Database connection failed'
            }), 500
        
        cursor = conn.cursor(dictionary=True)
        
        # Check user credentials and get subscription status from database
        cursor.execute("""
            SELECT id, username, password, status, expiry 
            FROM users 
            WHERE username = %s
        """, (username,))
        
        user = cursor.fetchone()
        
        if not user:
            cursor.close()
            conn.close()
            print(f"❌ User '{username}' not found in database")
            return jsonify({
                'success': False,
                'message': 'Invalid username or password'
            }), 401
        
        # Hash the provided password with MD5 for comparison
        hashed_password = md5_hash(password)
        
        print(f"🔍 Password comparison:")
        print(f"   Database MD5: '{user['password']}'")
        print(f"   Provided MD5: '{hashed_password}'")
        print(f"   Match: {user['password'] == hashed_password}")
        
        # Verify password using MD5 hash
        if user['password'] != hashed_password:
            cursor.close()
            conn.close()
            print(f"❌ MD5 password mismatch for user '{username}'")
            return jsonify({
                'success': False,
                'message': 'Invalid username or password'
            }), 401
        
        print(f"✅ MD5 password verified for user '{username}'")
        
        # Get subscription data from database
        db_status = user['status']
        db_expiry = user['expiry']
        
        # Format expiry for response
        if db_expiry:
            if isinstance(db_expiry, str):
                expiry_str = db_expiry
            else:
                expiry_str = db_expiry.strftime('%Y-%m-%d')
        else:
            expiry_str = None
        
        # Check subscription validity
        current_date = date.today()
        is_subscription_active = False
        
        if db_status == 'active':
            if db_expiry is None:
                # No expiry date = subscription never expires
                is_subscription_active = True
                print(f"✅ User '{username}' has active subscription with no expiry")
            else:
                # Convert expiry to date for comparison
                if isinstance(db_expiry, str):
                    db_expiry_date = datetime.strptime(db_expiry, '%Y-%m-%d').date()
                else:
                    db_expiry_date = db_expiry
                
                # Ensure both are date objects for comparison
                if isinstance(db_expiry_date, datetime):
                    db_expiry_date = db_expiry_date.date()
                
                print(f"🔍 User '{username}' expiry: {db_expiry_date} (type: {type(db_expiry_date)})")
                print(f"🔍 Today: {current_date} (type: {type(current_date)})")
                
                is_subscription_active = db_expiry_date >= current_date
                print(f"🔍 Subscription active: {is_subscription_active}")
        
        cursor.close()
        conn.close()
        
        # Prepare response
        response_data = {
            'success': True,
            'message': 'Authentication successful',
            'user': {
                'id': user['id'],
                'username': user['username'],
                'status': db_status,
                'expiry': expiry_str
            },
            'subscription_active': is_subscription_active
        }
        
        # Modify message based on subscription status
        if is_subscription_active:
            response_data['message'] = 'Authentication successful - Active subscription'
            print(f"🎉 Authentication successful for '{username}' - Active subscription")
            return jsonify(response_data), 200
        else:
            response_data['success'] = False
            response_data['message'] = 'Subscription inactive or expired'
            print(f"⚠️ Authentication successful for '{username}' but subscription inactive")
            return jsonify(response_data), 403
            
    except Exception as e:
        print(f"❌ Server error in /authenticate: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({
            'success': False,
            'message': f'Server error: {str(e)}'
        }), 500

@app.route('/status', methods=['GET'])
def status():
    """API status check"""
    try:
        # Test database connection
        conn = get_db_connection()
        if conn and conn.is_connected():
            db_status = 'connected'
            conn.close()
        else:
            db_status = 'disconnected'
        
        return jsonify({
            'status': 'online',
            'database': db_status,
            'message': 'Authentication API is running',
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': f'Status check failed: {str(e)}'
        }), 500

if __name__ == '__main__':
    print("🔧 Starting Flask Authentication API...")
    print("🐍 Using virtual environment:", sys.prefix)
    print("📁 Loading environment from: /etc/demo/.venv")
    
    # Test database connection on startup
    print("🔌 Testing database connection...")
    conn = get_db_connection()
    if conn:
        print("✅ Database connection successful")
        conn.close()
    else:
        print("❌ Database connection failed - check your .venv file")
        sys.exit(1)
    
    print("🚀 Starting Flask server on http://localhost:5000")
    print("🔍 MD5 password hashing enabled")
    app.run(host='localhost', port=5000, debug=False)
