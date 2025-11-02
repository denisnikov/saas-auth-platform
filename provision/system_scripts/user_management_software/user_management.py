#!/usr/bin/env python3
"""
User Management Script
Lists users from database and allows editing subscription status and expiry dates
Uses environment variables from .venv file
"""

import os
import mysql.connector
from mysql.connector import Error
from datetime import datetime, timedelta
import sys

def load_env_file(env_path):
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
        print(f"Error: Environment file not found at {env_path}")
        sys.exit(1)
    except Exception as e:
        print(f"Error reading environment file: {e}")
        sys.exit(1)

def create_db_connection(env_vars):
    """Create database connection using environment variables"""
    try:
        connection = mysql.connector.connect(
            host=env_vars.get('DB_HOST', 'localhost'),
            database=env_vars.get('DB_NAME', 'your_database_name'),
            user=env_vars.get('DB_USER', 'your_username'),
            password=env_vars.get('DB_PASS', 'your_password')
        )
        return connection
    except Error as e:
        print(f"Error connecting to MySQL database: {e}")
        sys.exit(1)

def get_all_users(connection):
    """Get all users from the database"""
    try:
        cursor = connection.cursor(dictionary=True)
        
        # Get all users with status and expiry
        cursor.execute("""
            SELECT id, username, password, status, expiry
            FROM users 
            ORDER BY id
        """)
        users = cursor.fetchall()
        cursor.close()
        return users
    except Error as e:
        print(f"Error fetching users: {e}")
        return []

def display_users(users):
    """Display users in a formatted table"""
    if not users:
        print("No users found in the database.")
        return
    
    print("\n" + "=" * 90)
    print(f"{'ID':<4} {'Username':<20} {'Status':<10} {'Expiry':<12} {'Days Left':<10} {'Valid':<6}")
    print("-" * 90)
    
    for user in users:
        user_id = user['id']
        username = user['username'][:18] + '..' if len(user['username']) > 18 else user['username']
        status = user['status']
        expiry = user['expiry']
        
        # Calculate days left and validity
        if expiry:
            expiry_date = expiry if isinstance(expiry, datetime) else datetime.strptime(str(expiry), '%Y-%m-%d')
            days_left = (expiry_date - datetime.now()).days
            is_valid = days_left >= 0 and status == 'active'
            expiry_str = expiry_date.strftime('%Y-%m-%d')
            days_left_str = f"{days_left} days"
            valid_str = "Yes" if is_valid else "No"
        else:
            expiry_str = "Never"
            days_left_str = "N/A"
            valid_str = "Yes" if status == 'active' else "No"
        
        # Color coding for status
        if status == 'active':
            status_display = f"\033[92m{status:<10}\033[0m"  # Green
        else:
            status_display = f"\033[91m{status:<10}\033[0m"  # Red
            
        # Color coding for validity
        if valid_str == "Yes":
            valid_display = f"\033[92m{valid_str:<6}\033[0m"  # Green
        else:
            valid_display = f"\033[91m{valid_str:<6}\033[0m"  # Red
            
        print(f"{user_id:<4} {username:<20} {status_display} {expiry_str:<12} {days_left_str:<10} {valid_display}")

def get_user_by_id(connection, user_id):
    """Get a specific user by ID"""
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute("""
            SELECT id, username, password, status, expiry
            FROM users 
            WHERE id = %s
        """, (user_id,))
        user = cursor.fetchone()
        cursor.close()
        return user
    except Error as e:
        print(f"Error fetching user: {e}")
        return None

def update_user_subscription(connection, user_id, new_status, new_expiry):
    """Update user's subscription status and expiry date"""
    try:
        cursor = connection.cursor()
        
        cursor.execute("""
            UPDATE users 
            SET status = %s, expiry = %s 
            WHERE id = %s
        """, (new_status, new_expiry, user_id))
        
        connection.commit()
        cursor.close()
        return True
    except Error as e:
        print(f"Error updating subscription: {e}")
        return False

def parse_date_input(date_input):
    """Parse various date input formats"""
    if not date_input or date_input.lower() == 'never':
        return None
    
    # Try different date formats
    formats = [
        '%Y-%m-%d',
        '%Y/%m/%d',
        '%m/%d/%Y',
        '%d/%m/%Y',
        '%Y.%m.%d'
    ]
    
    for fmt in formats:
        try:
            return datetime.strptime(date_input, fmt).date()
        except ValueError:
            continue
    
    # Try relative time (e.g., "+30 days")
    if date_input.startswith('+'):
        try:
            days = int(date_input[1:].split()[0])
            return (datetime.now() + timedelta(days=days)).date()
        except ValueError:
            pass
    
    return None

def main():
    # Load environment variables
    env_path = "/etc/demo/.venv"  # Change this to your .venv file path
    env_vars = load_env_file(env_path)
    
    # Create database connection
    connection = create_db_connection(env_vars)
    
    while True:
        # Display all users
        users = get_all_users(connection)
        display_users(users)
        
        print("\nOptions:")
        print("1. Edit user subscription")
        print("2. Refresh list")
        print("3. Exit")
        
        choice = input("\nEnter your choice (1-3): ").strip()
        
        if choice == '1':
            try:
                user_id = int(input("Enter user ID to edit: ").strip())
            except ValueError:
                print("Invalid user ID. Please enter a number.")
                continue
            
            user = get_user_by_id(connection, user_id)
            if not user:
                print(f"User with ID {user_id} not found.")
                continue
            
            print(f"\nEditing user: {user['username']} (ID: {user['id']})")
            print(f"Current status: {user['status']}")
            print(f"Current expiry: {user['expiry'] or 'Never'}")
            
            # Status selection
            print("\nSelect new status:")
            print("1. active")
            print("2. inactive")
            status_choice = input("Enter choice (1-2): ").strip()
            
            if status_choice == '1':
                new_status = 'active'
            elif status_choice == '2':
                new_status = 'inactive'
            else:
                print("Invalid choice. Using current status.")
                new_status = user['status']
            
            # Expiry date input
            print("\nEnter new expiry date:")
            print("Examples:")
            print("  - 'never' or leave empty for no expiry")
            print("  - '2024-12-31' for specific date")
            print("  - '+30' for 30 days from now")
            print("  - 'current' to keep current expiry")
            
            expiry_input = input("New expiry: ").strip()
            
            if expiry_input.lower() == 'current':
                new_expiry = user['expiry']
            elif expiry_input.lower() == 'never' or expiry_input == '':
                new_expiry = None
            else:
                new_expiry = parse_date_input(expiry_input)
                if not new_expiry:
                    print("Invalid date format. Keeping current expiry.")
                    new_expiry = user['expiry']
            
            # Display changes and confirm
            print(f"\nChanges to be made:")
            print(f"  Status: {user['status']} -> {new_status}")
            print(f"  Expiry: {user['expiry'] or 'Never'} -> {new_expiry or 'Never'}")
            
            confirm = input("\nApply these changes? (y/n): ").strip().lower()
            
            if confirm == 'y':
                if update_user_subscription(connection, user_id, new_status, new_expiry):
                    print("Subscription updated successfully!")
                else:
                    print("Failed to update subscription.")
            else:
                print("Update cancelled.")
        
        elif choice == '2':
            continue  # Refresh the list
        
        elif choice == '3':
            print("Goodbye!")
            break
        
        else:
            print("Invalid choice. Please enter 1, 2, or 3.")
        
        input("\nPress Enter to continue...")
    
    # Close database connection
    connection.close()

if __name__ == "__main__":
    main()
