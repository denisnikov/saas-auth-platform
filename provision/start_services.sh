#!/bin/bash

echo "🔧 Starting Authentication System Services"

# Check if Flask API is already running in screen
if screen -list | grep -q "flask_api"; then
    echo "🔄 Flask API is already running. Restarting..."
    screen -S flask_api -X quit
    sleep 2
fi

# Start Flask API in a screen session using the virtual environment
echo "🚀 Starting Flask API in screen session (using virtual environment)..."
screen -dmS flask_api bash -c '
    echo "Starting Flask Authentication API with virtual environment..."
    cd /var/www/api
    source venv/bin/activate
    python3 app.py
    echo "Flask API stopped. Press Ctrl+A then D to detach, or wait to exit."
    sleep 5
'

# Wait a moment for the API to start
sleep 3

# Check if services are running
echo "📊 Service Status:"
echo "------------------"

# Check Apache
if systemctl is-active --quiet apache2; then
    echo "✅ Apache2: RUNNING"
else
    echo "❌ Apache2: STOPPED"
    echo "   Starting Apache2..."
    sudo systemctl start apache2
fi

# Check MySQL
if systemctl is-active --quiet mysql; then
    echo "✅ MySQL: RUNNING"
else
    echo "❌ MySQL: STOPPED"
    echo "   Starting MySQL..."
    sudo systemctl start mysql
fi

# Check Flask API
if screen -list | grep -q "flask_api"; then
    echo "✅ Flask API: RUNNING (in screen session with venv)"
    echo "   To view: screen -r flask_api"
    echo "   To detach: Ctrl+A then D"
else
    echo "❌ Flask API: FAILED TO START"
fi

echo ""
echo "🌐 Web Interface: http://$(hostname -I | awk '{print $1}')/login.php"
echo "🔌 API Endpoint: http://localhost:5000"
echo ""
echo "📋 Screen sessions:"
screen -list
echo ""
echo "💡 Commands:"
echo "   View API logs: screen -r flask_api"
echo "   Stop API: screen -S flask_api -X quit"
echo "   Restart everything: ./start_services.sh"
