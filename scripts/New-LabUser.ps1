param(
    [Parameter(Mandatory=$true)][string]$Nombre,
    [Parameter(Mandatory=$true)][string]$Apellido
)

$sam = ("$Nombre.$Apellido").ToLower()
$ouPath = "OU=Usuarios,OU=LAB-Corp,DC=lab,DC=local"
$upn = "$sam@lab.local"
$clavetemp = ConvertTo-SecureString "Cambiar123!" -AsPlainText -Force

New-ADUser -Name "$Nombre $Apellido" `
    -GivenName $Nombre -Surname $Apellido `
    -SamAccountName $sam -UserPrincipalName $upn `
    -Path $ouPath -AccountPassword $clavetemp `
    -Enabled $true -ChangePasswordAtLogon $true

Add-ADGroupMember -Identity "GG-TI" -Members $sam

Write-Host "Usuario $sam creado correctamente" -ForegroundColor Green
