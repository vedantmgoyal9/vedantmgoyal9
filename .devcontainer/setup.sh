#!/usr/bin/env bash

# postAttachCommand: "bash /workspace/.devcontainer/setup.sh"
# postStartCommand: "bash /workspace/.devcontainer/setup.sh"
if [ -n "$1" ]; then
    echo "Mode: postAttachCmd/postStartCmd"
    brew update && brew upgrade
    exit
fi

# Directories
script_folder="$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)"
workspaces_folder="$(cd "${script_folder}/../.." && pwd)"

# Installing softwares
wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" # Register Microsoft repository GPG keys
sudo dpkg -i packages-microsoft-prod.deb # Register Microsoft repository GPG keys
rm packages-microsoft-prod.deb # Delete Microsoft repository GPG keys file
sudo apt update # Run apt update
sudo apt install -y neofetch openjdk-19-jdk powershell
# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
# Install brew and add to path, reload shell
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.bashrc
source ~/.bashrc
nvm install --lts
# Install oh-my-posh
brew install jandedobbeleer/oh-my-posh/oh-my-posh gh go hugo
# Copy PowerShell Profile
mkdir -p $(pwsh -Command '$PROFILE | Split-Path')
cp "${workspaces_folder}/vedantmgoyal2009/.devcontainer/profile.ps1" $(pwsh -Command '$PROFILE')
# Add oh-my-posh to bash profile
echo 'eval "$(oh-my-posh init bash -c $(brew --prefix oh-my-posh)/themes/takuya.omp.json)"' >> /home/vscode/.bashrc
# Install powershell-yaml module for winget-pkgs-automation
pwsh -Command "Install-Module -Name powershell-yaml -Force"

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

# Clone repositories
clone-repo "vedantmgoyal2009/winget-pkgs-automation"
clone-repo "vedantmgoyal2009/winget-releaser"
clone-repo "vedantmgoyal2009/homebrew-tap"

# Install npm node_modules
cd "${workspaces_folder}/winget-releaser"
sudo npm install

# Multi-root workspace
cd "${workspaces_folder}/vedantmgoyal2009"
# code-insiders multi-root.code-workspace
