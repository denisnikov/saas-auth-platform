#!/usr/bin/env python3
"""
Subscription Status Updater
Cron job that runs daily to update user subscription statuses based on expiry dates
"""

import mysql.connector
from datetime import datetime, date
import sys
import os

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
            database=env_vars.get('DB_NAME', 'your_database_name'),
            user=env_vars.get('DB_USER', 'your_username'),
            password=env_vars.get('DB_PASS', 'your_password'),
            autocommit=True
        )
        return connection
    except mysql.connector.Error as e:
        print(f"❌ Database connection error: {e}")
        return None

def update_subscription_statuses():
    """Update user subscription statuses based on expiry dates"""
    print(f"🔄 Starting subscription status update - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    conn = get_db_connection()
    if not conn:
        print("❌ Failed to connect to database")
        return False
    
    try:
        cursor = conn.cursor(dictionary=True)
        
        # Get current date
        current_date = date.today()
        print(f"📅 Current date: {current_date}")
        
        # Count users before update
        cursor.execute("SELECT COUNT(*) as total_users FROM users")
        total_users = cursor.fetchone()['total_users']
        
        cursor.execute("""
            SELECT COUNT(*) as active_users 
            FROM users 
            WHERE status = 'active'
        """)
        active_users_before = cursor.fetchone()['active_users']
        
        print(f"📊 Total users: {total_users}")
        print(f"📊 Active users before update: {active_users_before}")
        
        # Update users with expired subscriptions to inactive
        update_expired_query = """
            UPDATE users 
            SET status = 'inactive' 
            WHERE status = 'active' 
            AND expiry IS NOT NULL 
            AND expiry < %s
        """
        
        cursor.execute(update_expired_query, (current_date,))
        expired_count = cursor.rowcount
        
        print(f"🔴 Set {expired_count} users to inactive (subscription expired)")
        
        # Update users with future expiry dates back to active
        # This handles cases where a user purchases a new subscription
        update_active_query = """
            UPDATE users 
            SET status = 'active' 
            WHERE status = 'inactive' 
            AND expiry IS NOT NULL 
            AND expiry >= %s
        """
        
        cursor.execute(update_active_query, (current_date,))
        reactivated_count = cursor.rowcount
        
        print(f"🟢 Reactivated {reactivated_count} users (subscription valid)")
        
        # Handle users with lifetime subscriptions (no expiry date)
        update_lifetime_query = """
            UPDATE users 
            SET status = 'active' 
            WHERE status = 'inactive' 
            AND expiry IS NULL
        """
        
        cursor.execute(update_lifetime_query)
        lifetime_reactivated = cursor.rowcount
        
        print(f"⭐ Reactivated {lifetime_reactivated} lifetime subscription users")
        
        # Count users after update
        cursor.execute("""
            SELECT COUNT(*) as active_users 
            FROM users 
            WHERE status = 'active'
        """)
        active_users_after = cursor.fetchone()['active_users']
        
        print(f"📊 Active users after update: {active_users_after}")
        print(f"📈 Net change: {active_users_after - active_users_before}")
        
        # Get detailed breakdown
        cursor.execute("""
            SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN expiry IS NULL THEN 1 ELSE 0 END) as lifetime,
                SUM(CASE WHEN expiry IS NOT NULL AND expiry >= %s THEN 1 ELSE 0 END) as active_with_expiry,
                SUM(CASE WHEN expiry IS NOT NULL AND expiry < %s THEN 1 ELSE 0 END) as expired
            FROM users 
            WHERE status = 'active'
        """, (current_date, current_date))
        
        breakdown = cursor.fetchone()
        
        print("\n📋 Active Users Breakdown:")
        print(f"   • Total active: {breakdown['total']}")
        print(f"   • Lifetime subscriptions: {breakdown['lifetime']}")
        print(f"   • Active with expiry: {breakdown['active_with_expiry']}")
        print(f"   • Expired (should be 0): {breakdown['expired']}")
        
        cursor.close()
        conn.close()
        
        print(f"✅ Subscription status update completed successfully")
        return True
        
    except mysql.connector.Error as e:
        print(f"❌ Database error during update: {e}")
        conn.close()
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        conn.close()
        return False

def main():
    """Main function"""
    print("=" * 60)
    print("🔐 AUTOMATIC SUBSCRIPTION STATUS UPDATER")
    print("=" * 60)
    
    success = update_subscription_statuses()
    
    if success:
        print(f"🎉 Cron job completed successfully - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        sys.exit(0)
    else:
        print(f"💥 Cron job failed - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        sys.exit(1)

if __name__ == "__main__":
    main()
