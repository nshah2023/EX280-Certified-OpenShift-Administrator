#!/bin/bash

# OpenShift Route and Service Automation
# Automatically creates secure routes with SSL for applications

APP_NAME=${1}
PORT=${2:-8080}
HOSTNAME_SUFFIX=${3:-"apps.nishant-openshift-sandbox.westus3.aroapp.io"}

if [ -z "$APP_NAME" ]; then
    echo "Usage: $0 <app-name> [port] [hostname-suffix]"
    echo "Example: $0 apache 8080"
    exit 1
fi

echo "🚀 Automating route creation for: $APP_NAME"

# Check if service exists
if ! oc get service $APP_NAME >/dev/null 2>&1; then
    echo "❌ Service $APP_NAME not found!"
    exit 1
fi

# Create secure route with edge termination
echo "📡 Creating secure route..."
oc create route edge $APP_NAME-secure \
    --service=$APP_NAME \
    --hostname=$APP_NAME.$HOSTNAME_SUFFIX \
    --port=$PORT

# Create insecure route (for testing)
echo "📡 Creating insecure route..."
oc expose service/$APP_NAME \
    --hostname=$APP_NAME-insecure.$HOSTNAME_SUFFIX

# Display route information
echo ""
echo "✅ Routes created successfully!"
echo "🔒 Secure: https://$APP_NAME.$HOSTNAME_SUFFIX"
echo "🔓 Insecure: http://$APP_NAME-insecure.$HOSTNAME_SUFFIX"

# Test route accessibility
echo ""
echo "🧪 Testing route accessibility..."
curl -s -I https://$APP_NAME.$HOSTNAME_SUFFIX | head -1 || echo "❌ HTTPS route not accessible"
curl -s -I http://$APP_NAME-insecure.$HOSTNAME_SUFFIX | head -1 || echo "❌ HTTP route not accessible"