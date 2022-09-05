#!/usr/bin/env bash

# Directories
script_folder="$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)"
workspaces_folder="$(cd "${script_folder}/../.." && pwd)"

# Installing softwares
sudo apt-get update
sudo apt install npm neofetch default-jre default-jdk
pwsh -Command "Install-Module -Name powershell-yaml"
# Install oh-my-posh
brew tap jandedobbeleer/oh-my-posh
brew install oh-my-posh
# Copy PowerShell Profile
cp "${workspaces_folder}/vedantmgoyal2009/.devcontainer/profile.ps1" >> $(pwsh -Command '$PROFILE')
# Add oh-my-posh to profile and start oh-my-posh
echo 'eval "$(oh-my-posh --init --shell bash --config /workspaces/vedantmgoyal2009/.devcontainer/mytheme.omp.json)"' >> /home/vscode/.bashrc
eval "$(oh-my-posh --init --shell bash --config /workspaces/vedantmgoyal2009/.devcontainer/mytheme.omp.json)"

# Multi-repo setup
clone-repo()
{
    cd "${workspaces_folder}"
    if [ ! -d "$1" ]; then
        git clone "https://github.com/$1"
    else 
        echo "Already cloned $1"
    fi
}

clone-repo "vedantmgoyal2009/winget-releaser"
clone-repo "vedantmgoyal2009/winget-pkgs"

# Install npm node_modules
cd "${workspaces_folder}/vedantmgoyal2009"
sudo npm install && npx commitizen init cz-conventional-changelog
cd "${workspaces_folder}/winget-releaser"
sudo npm install

# Multi-root workspace
code multi-root.code-workspace