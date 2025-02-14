// filepath: /C:/Users/prime/OneDrive/Documents/GitHub/modded-k3s-setup/windows-uninstall.ps1

# 1. Remove the KUBECONFIG environment variable for the current user.
[System.Environment]::SetEnvironmentVariable("KUBECONFIG", $null, "User")
Write-Output "KUBECONFIG environment variable removed."

# 2. Remove the k8sdash entry from the Windows hosts file.
$hostsPath = "C:\Windows\System32\drivers\etc\hosts"
$entry = "127.0.0.1 k8sdash"
if (Test-Path $hostsPath) {
    $hostsContent = Get-Content $hostsPath
    $newContent = $hostsContent | Where-Object {$_ -notmatch [regex]::Escape($entry)}
    Set-Content $hostsPath $newContent
    Write-Output "Removed '$entry' from hosts file."
} else {
    Write-Output "Hosts file not found."
}

# 3. Remove the self-signed certificate from the Windows Trusted Root store.
# Adjust the thumbprint or other mechanism as needed to ensure the right cert is removed.
$store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root","LocalMachine")
$store.Open("ReadWrite")
# Find the certificate by subject name (customize "k3s-setup" if necessary)
$certs = $store.Certificates | Where-Object { $_.Subject -match "CN=k3s-setup" }
if ($certs.Count -gt 0) {
    foreach ($cert in $certs) {
        $store.Remove($cert)
        Write-Output "Removed certificate with Thumbprint: $($cert.Thumbprint)"
    }
} else {
    Write-Output "No matching certificate found in the Trusted Root store."
}
$store.Close()