$HomeBrew = '/home/linuxbrew/.linuxbrew/bin/brew'
$OhMyPosh = '/home/linuxbrew/.linuxbrew/bin/oh-my-posh'
(& $OhMyPosh init pwsh -c "$(& $HomeBrew --prefix oh-my-posh)/themes/takuya.omp.json")  | Invoke-Expression
