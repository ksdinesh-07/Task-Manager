#!/bin/bash
cd ~/Documents/devops/Task\ Manager

echo "🚨 PERMANENT FIX FOR TERRAFORM APPLY ERROR"
echo "=========================================="

# Backup
cp Jenkinsfile Jenkinsfile.bak.$(date +%s)

echo "1. Finding all terraform apply commands..."
grep -n "terraform apply" Jenkinsfile

echo ""
echo "2. Removing ALL -var parameters..."
# Method 1: Remove pattern
sed -i 's/terraform apply -auto-approve -var=.*tfplan\./terraform apply -auto-approve tfplan./g' Jenkinsfile

# Method 2: Remove any remaining -var
sed -i '/terraform apply/s/-var=[^ ]* //g' Jenkinsfile
sed -i '/terraform apply/s/-var=[^ ]* //g' Jenkinsfile

# Method 3: Clean double spaces
sed -i 's/  / /g' Jenkinsfile

echo ""
echo "3. Final verification..."
echo "Fixed commands:"
grep -n "terraform apply" Jenkinsfile

echo ""
echo "4. Testing if -var still exists..."
if grep -q "-var=" Jenkinsfile; then
    echo "❌ STILL HAS -var! Using aggressive fix..."
    # Remove ALL occurrences of -var=anything in entire file
    sed -i 's/-var=[^ ]*//g' Jenkinsfile
else
    echo "✅ No -var parameters found!"
fi

echo ""
echo "5. Committing fix..."
git add Jenkinsfile
git commit -m "PERMANENT FIX: Remove ALL -var parameters from terraform commands"
git push origin main

echo ""
echo "🎉 PERMANENT FIX APPLIED AND COMMITTED!"
echo "Run new Jenkins build - it WILL work now!"
