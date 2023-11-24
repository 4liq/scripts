
oh-my-posh init pwsh --config "C:/Users/twist/scoop/apps/oh-my-posh/current/themes/bubblesline.omp.json" | Invoke-Expression

$gitrepos = 'C:\Users\twist\Documents\GitHub'
$notes = 'D:\shared\Notes\'

function Start-Firefox {
	start-process "firefox.exe"
}

function Start-Sublime([string] $param) {
	if ($param) {
		start-process "C:\Program Files\Sublime Text 3\sublime_text.exe" $param
	} else {
		start-process "C:\Program Files\Sublime Text 3\sublime_text.exe" .
	}
}

function Start-MusikCube() {
	start-process "D:\idk\musikcube-cmd.exe"
}

function help-please() {
	write-host 'ff - start-firefox'
	write-host 'subl - start-sublime'
	write-host 'music - start-musikcube'
	write-host '$gitrepos'
	write-host '$notes'

}

set-alias ff start-firefox
set-alias subl start-sublime
set-alias music start-musikcube


