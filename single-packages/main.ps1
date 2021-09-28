# Download wingetcreate.exe, store token information and setup API headers
. .\initial_setup.ps1 # Another period to pass variables to the script
# Scripts which update single package at a time
.\signal.ps1
# Push script with updated last_checked_tag to repository
Write-Host -ForegroundColor Green "`nUpdating single-packages.json"
git config --global user.name 'winget-pkgs-automation'
git config --global user.email '83997633+vedantmgoyal2009@users.noreply.github.com'
git pull # to be on a safe side
git add .\single-packages.json
git commit -m "Update single-packages.json [$env:GITHUB_RUN_NUMBER]"
git push
# Clear authentication information
.\wingetcreate.exe token --clear
