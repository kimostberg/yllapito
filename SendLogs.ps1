$From = "senders@email.address"
$To = "receivers@email.address"
$Cc = "someone.elses@email.address"
$Subject = "$env:computername Log Files"
$Body = "Please find the attached log files."
$SMTPServer = "smtp.server.address"
$SMTPPort = 587
$LogDirectory = "$env:SystemDrive\maintenance\logs"

$Attachments = Get-ChildItem $LogDirectory | Select-Object -ExpandProperty FullName

$SecurePassword = Read-Host -Prompt "Please enter your email password" -AsSecureString
$Credential = New-Object System.Management.Automation.PSCredential $From, $SecurePassword

Send-MailMessage -From $From -to $To -Cc $Cc -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -Attachments $Attachments -UseSsl -Credential $Credential

if ($?) {
    Remove-Item $LogDirectory\*
} else {
    Write-Error "An error occurred while sending the email"
}