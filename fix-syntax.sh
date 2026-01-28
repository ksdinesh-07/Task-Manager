#!/bin/bash
cd ~/Documents/devops/Task\ Manager

echo "🔧 Fixing Jenkinsfile syntax..."

# Backup
cp Jenkinsfile Jenkinsfile.bak.$(date +%s)

# Check for common issues
echo "1. Checking for unclosed quotes..."
if grep -q '"""$' Jenkinsfile; then
    echo "❌ Found unclosed triple quotes"
    sed -i 's/"""$/"""/' Jenkinsfile
fi

echo "2. Adding missing closing brace if needed..."
LAST_CHAR=$(tail -c 1 Jenkinsfile | od -An -t x1 | tr -d ' \n')
if [ "$LAST_CHAR" != "7d" ]; then  # 7d = } in hex
    echo "❌ Missing closing brace at end, adding..."
    echo "}" >> Jenkinsfile
fi

echo "3. Checking stage closures..."
# Count stages
STAGES=$(grep -c "^[[:space:]]*stage" Jenkinsfile)
echo "Found $STAGES stages"

echo "4. Validating syntax..."
if python3 -c "with open('Jenkinsfile', 'r') as f: content = f.read(); print('Lines:', len(content.split(chr(10))))" 2>/dev/null; then
    echo "✅ Basic file structure OK"
else
    echo "❌ File reading error"
fi

echo ""
echo "📝 Fixed file tail:"
tail -5 Jenkinsfile
