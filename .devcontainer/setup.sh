#!/usr/bin/env bash

sudo apt-get update
sudo apt-get install -y wget apt-transport-https software-properties-common # Install pre-requisite packages
wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb # Download the Microsoft repository GPG keys
sudo dpkg -i packages-microsoft-prod.deb # Register the Microsoft repository GPG keys
sudo apt-get update # Update the list of packages after we added packages.microsoft.com
sudo apt-get install -y powershell # Install PowerShell

# Multi-repo setup
script_folder="$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)"
workspaces_folder="$(cd "${script_folder}/../.." && pwd)"

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
