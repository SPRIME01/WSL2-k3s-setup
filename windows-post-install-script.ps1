# 1. Set the KUBECONFIG environment variable persistently for the current user.
$kubeconfigValue = "$env:USERPROFILE\.kube\k3s.yaml"
$currentValue = [System.Environment]::GetEnvironmentVariable("KUBECONFIG", "User")
if ($currentValue -ne $kubeconfigValue) {
    Write-Output "Setting KUBECONFIG to $kubeconfigValue for the current user..."
    [System.Environment]::SetEnvironmentVariable("KUBECONFIG", $kubeconfigValue, "User")
}
else {
    Write-Output "KUBECONFIG is already set."
}

# 2. Update the Windows hosts file to include the k8sdash mapping.
$hostsPath = "C:\Windows\System32\drivers\etc\hosts"
$entry = "127.0.0.1 k8sdash"
$hostsContent = Get-Content $hostsPath -ErrorAction SilentlyContinue
if ($hostsContent -notcontains $entry) {
    Write-Output "Adding '$entry' to $hostsPath..."
    Add-Content -Path $hostsPath -Value $entry
}
else {
    Write-Output "Hosts file already contains '$entry'."
}

# 3. Install the self-signed certificate into the Windows Trusted Root Certificates.
# Adjust the certificate path if needed.
$certPath = "C:\Users\prime\OneDrive\Documents\GitHub\modded-k3s-setup\cluster-system\cert-manager\certs\tls.crt"
if (Test-Path $certPath) {
    Write-Output "Importing certificate from $certPath..."
    # Import the certificate into the Root store of the local machine.
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $cert.Import($certPath)
    
    # Open the local machine's Root store - Requires running as Administrator.
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root","LocalMachine")
    $store.Open("ReadWrite")
    
    # Check if the certificate is already installed.
    $existing = $store.Certificates | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }
    if ($existing.Count -eq 0) {
        $store.Add($cert)
        Write-Output "Certificate imported successfully."
    }
    else {
        Write-Output "Certificate is already installed in the Root store."
    }
    $store.Close()
}
else {
    Write-Output "Certificate not found at $certPath"
}