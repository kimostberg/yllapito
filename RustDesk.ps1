# Download latest dotnet/codeformatter release from github

$repo = "rustdesk/rustdesk"

$releases = "https://api.github.com/repos/$repo/releases"

Write-Host Determining latest release
$tag = (Invoke-WebRequest $releases | ConvertFrom-Json)[0].tag_name

$file = "rustdesk-$tag-x86_64.exe"
$download = "https://github.com/$repo/releases/download/$tag/$file"
#$name = $file.Split(".")[0]
$downloaded = "c:\maintenance\rustdesk-host=rustdesk.ktj.solutions,key=PsMZiRn9VcFThwEW15k3CSHNq6TPN54WXkdIWwKEvrk=.exe"

Write-Host Dowloading latest release
Invoke-WebRequest $download -Out $downloaded