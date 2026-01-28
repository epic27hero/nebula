#!/bin/bash

# GitLab Credentials from CI/CD variables
GITLAB_TOKEN="PROJECT_NEBULA_ACCESS_TOKEN"
GITLAB_USER="root"
GITLAB_PASS="your_password_here"  # If needed
GITLAB_URL="http://192.168.0.190"
GITLAB_REPO="root/project_nebula.git"

echo "=== Testing GitLab Access ==="
echo ""

# Test 1: Check GitLab is running
echo "1️⃣ Testing GitLab server connectivity..."
if curl -s -I "$GITLAB_URL" | grep -q "200\|302"; then
    echo "✅ GitLab is accessible at $GITLAB_URL"
else
    echo "❌ GitLab is not accessible"
    exit 1
fi

echo ""

# Test 2: Test with token in URL
echo "2️⃣ Testing repo access with token in URL..."
echo "URL: http://$GITLAB_USER:$GITLAB_TOKEN@192.168.0.190/$GITLAB_REPO"
curl -s -I "http://$GITLAB_USER:$GITLAB_TOKEN@192.168.0.190/$GITLAB_REPO" | head -3

echo ""

# Test 3: List projects
echo "3️⃣ Testing API access to list projects..."
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/projects" | head -c 200
echo "..."

echo ""
echo "4️⃣ Testing repo clone with token..."
rm -rf /tmp/test-clone
timeout 10 git clone "http://$GITLAB_USER:$GITLAB_TOKEN@192.168.0.190/$GITLAB_REPO" /tmp/test-clone 2>&1 | head -5

if [ -d /tmp/test-clone/.git ]; then
    echo "✅ Successfully cloned repo!"
    ls -la /tmp/test-clone/
else
    echo "❌ Clone failed - check credentials"
fi
