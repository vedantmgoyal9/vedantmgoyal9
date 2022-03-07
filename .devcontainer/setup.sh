#!/usr/bin/env bash

# Directories
script_folder="$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)"
workspaces_folder="$(cd "${script_folder}/../.." && pwd)"

# Install latest NodeJS
curl -fsSL https://deb.nodesource.com/setup_17.x | sudo -E bash -
sudo apt-get install -y nodejs

# Installing latest poweshell
sudo apt-get update
sudo apt-get install -y wget apt-transport-https software-properties-common # Install pre-requisite packages
wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb # Download the Microsoft repository GPG keys
sudo dpkg -i packages-microsoft-prod.deb # Register the Microsoft repository GPG keys
sudo apt-get update # Update the list of packages after we added packages.microsoft.com
sudo apt-get install -y powershell # Install PowerShell
# Install powershell-yaml module for winget-pkgs-automation
pwsh -Command "Install-Module -Name powershell-yaml"

# Install homebrew
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# Run these two commands in your terminal to add Homebrew to your PATH:
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/vscode/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
# Install Homebrew's dependencies if you have sudo access:
sudo apt-get install -y build-essential
# Install oh-my-posh
brew tap jandedobbeleer/oh-my-posh
brew install oh-my-posh
# Configure PowerShell Profile
pwshProfilePath=$(pwsh -Command '$PROFILE')
mkdir -p /home/vscode/.config/powershell
touch $pwshProfilePath
profile='/home/linuxbrew/.linuxbrew/bin/oh-my-posh --init --shell pwsh --config /workspaces/vedantmgoyal2009/.devcontainer/mytheme.omp.json | Invoke-Expression'
echo $profile >> $pwshProfilePath
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

if [ "${CODESPACES}" = "true" ]; then
    # Remove the default credential helper
    sudo sed -i -E 's/helper =.*//' /etc/gitconfig

    # Add one that just uses secrets available in the Codespace
    git config --global credential.helper '!f() { sleep 1; echo "username=${GITHUB_USER}"; echo "password=${MYSUPERSECRETINFORMATION}"; }; f'
fi

clone-repo "vedantmgoyal2009/winget-pkgs"

# Install commitizen
cd "${workspaces_folder}/vedantmgoyal2009"
sudo npm install commitizen @commitlint/config-conventional -g && npx commitizen init cz-conventional-changelog

# Multi-root workspace
code multi-root.code-workspace
