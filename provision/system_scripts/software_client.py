#!/usr/bin/env python3
"""
Local Subscription Status Checker
Requests username/password and checks subscription status via API
"""

import requests
import json
import sys
from getpass import getpass
from datetime import datetime

class SubscriptionChecker:
    def __init__(self, api_url="http://localhost:5000"):
        self.api_url = api_url.rstrip('/')
        self.session = requests.Session()
    
    def check_api_status(self):
        """Check if the API is reachable"""
        try:
            response = self.session.get(f"{self.api_url}/status", timeout=10)
            return response.status_code == 200
        except requests.exceptions.RequestException:
            return False
    
    def check_subscription_status(self, username, password):
        """
        Check subscription status for the given user
        """
        try:
            # Prepare payload with only username and password
            payload = {
                'username': username,
                'password': password
            }
            
            print("🔐 Checking subscription status...")
            response = self.session.post(
                f"{self.api_url}/authenticate",
                json=payload,
                headers={'Content-Type': 'application/json'},
                timeout=30
            )
            
            return self._handle_response(response)
            
        except requests.exceptions.Timeout:
            return {
                'success': False,
                'message': 'Request timeout - server took too long to respond',
                'subscription_active': False
            }
        except requests.exceptions.ConnectionError:
            return {
                'success': False,
                'message': f'Cannot connect to {self.api_url}. Make sure Flask app is running.',
                'subscription_active': False
            }
        except Exception as e:
            return {
                'success': False,
                'message': f'Unexpected error: {str(e)}',
                'subscription_active': False
            }
    
    def _handle_response(self, response):
        """Handle API response"""
        try:
            data = response.json()
        except json.JSONDecodeError:
            return {
                'success': False,
                'message': f'Invalid response from server (HTTP {response.status_code})',
                'subscription_active': False
            }
        
        if response.status_code == 200:
            return {
                'success': True,
                'message': data.get('message', 'Authentication successful'),
                'user': data.get('user', {}),
                'subscription_active': data.get('subscription_active', False)
            }
        elif response.status_code == 403:
            return {
                'success': False,
                'message': data.get('message', 'Subscription inactive or expired'),
                'user': data.get('user', {}),
                'subscription_active': False
            }
        elif response.status_code == 401:
            return {
                'success': False,
                'message': data.get('message', 'Invalid username or password'),
                'subscription_active': False
            }
        else:
            return {
                'success': False,
                'message': f'Error (HTTP {response.status_code}): {data.get("message", "Unknown error")}',
                'subscription_active': False
            }
    
    def format_expiry_display(self, expiry_date):
        """Format expiry date for display with days remaining"""
        if not expiry_date:
            return "Never expires"
        
        try:
            # Parse expiry date
            expiry = datetime.strptime(expiry_date, '%Y-%m-%d').date()
            today = datetime.now().date()
            days_remaining = (expiry - today).days
            
            if days_remaining > 0:
                return f"{expiry_date} ({days_remaining} days remaining)"
            elif days_remaining == 0:
                return f"{expiry_date} (Expires today!)"
            else:
                return f"{expiry_date} (Expired {abs(days_remaining)} days ago)"
                
        except ValueError:
            return f"{expiry_date} (Invalid date format)"

def display_subscription_status(result, checker):
    """Display subscription status in a user-friendly format"""
    print("\n" + "="*50)
    
    if result['success'] and result['subscription_active']:
        user_info = result.get('user', {})
        username = user_info.get('username', 'Unknown')
        status = user_info.get('status', 'unknown')
        expiry = user_info.get('expiry')
        
        print("✅ SUBSCRIPTION STATUS: ACTIVE")
        print("="*50)
        print(f"👤 Username: {username}")
        print(f"🆔 User ID: {user_info.get('id', 'N/A')}")
        print(f"📊 Status: {status.upper()}")
        print(f"📅 Expiry: {checker.format_expiry_display(expiry)}")
        print(f"💡 Message: {result['message']}")
        
    else:
        print("❌ SUBSCRIPTION STATUS: INACTIVE")
        print("="*50)
        print(f"💡 Message: {result['message']}")
        
        # Show additional user info if available
        if 'user' in result and result['user']:
            user_info = result['user']
            print(f"👤 Username: {user_info.get('username', 'Unknown')}")
            print(f"📊 Current Status: {user_info.get('status', 'unknown')}")
            print(f"📅 Current Expiry: {checker.format_expiry_display(user_info.get('expiry'))}")

def main():
    print("🔒 Subscription Status Checker")
    print("="*40)
    
    # Initialize checker
    checker = SubscriptionChecker()
    
    # Check API connection
    print("📡 Checking API connection...")
    if not checker.check_api_status():
        print("❌ Cannot connect to the authentication server")
        print("Please make sure:")
        print("1. Your Flask app is running (python3 app.py)")
        print("2. It's running on http://localhost:5000")
        print("3. No firewall is blocking port 5000")
        sys.exit(1)
    
    print("✅ Connected to authentication server")
    print()
    
    # Get user credentials
    try:
        username = input("Enter username: ").strip()
        if not username:
            print("❌ Username cannot be empty")
            sys.exit(1)
        
        password = getpass("Enter password: ")
        if not password:
            print("❌ Password cannot be empty")
            sys.exit(1)
            
    except KeyboardInterrupt:
        print("\n\n❌ Operation cancelled by user")
        sys.exit(1)
    
    # Check subscription status
    result = checker.check_subscription_status(username, password)
    
    # Display results
    display_subscription_status(result, checker)
    
    # Exit code based on subscription status
    if result.get('subscription_active'):
        print("\n🎉 Access granted! Subscription is active.")
        sys.exit(0)
    else:
        print("\n🚫 Access denied! Subscription is not active.")
        sys.exit(1)

if __name__ == "__main__":
    main()
