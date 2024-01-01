#region https://github.com/nvm-sh/nvm/issues/2058#issuecomment-870814344
## Based on: https://github.com/nvm-sh/nvm/issues/2058#issuecomment-735551849
function Initialize-NvmPath {
    $ENV:NVM_DIR = "$HOME/.nvm"
    $bashPathWithNvm = bash -c 'source $NVM_DIR/nvm.sh && echo $PATH'
    $env:PATH = $bashPathWithNvm
}

function nvm {
    $quotedArgs = ($args | ForEach-Object { "'$_'" }) -join ' '
    $command = 'source $NVM_DIR/nvm.sh && nvm {0}' -f $quotedArgs
    bash -c $command
}

Initialize-NvmPath
#endregion https://github.com/nvm-sh/nvm/issues/2058#issuecomment-870814344

# Add homebrew to PATH
& '/home/linuxbrew/.linuxbrew/bin/brew' shellenv | Invoke-Expression

# Initialize oh-my-posh
oh-my-posh init pwsh -c "$(brew --prefix oh-my-posh)/themes/takuya.omp.json"  | Invoke-Expression

Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineOption -PredictionSource History
