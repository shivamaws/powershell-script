# Ensure you are logged into Azure
# Connect-AzAccount # Uncomment this line if you need to authenticate

# Parameters
$keyVaultName = ""  # Replace with your Key Vault name
$secretFilePath = "C:\Users\Desktop\testvm1.txt"  # Path to the input file with secret names

# Check if the file exists
if (-not (Test-Path $secretFilePath)) {
    Write-Error "The file $secretFilePath does not exist."
    exit
}

# Read the secret names from the file
$secretNames = Get-Content -Path $secretFilePath

# Check each secret in the Key Vault
foreach ($secretName in $secretNames) {
    try {
        # Trim any whitespace from the secret name
        $secretName = $secretName.Trim()

        # Skip empty lines
        if ([string]::IsNullOrEmpty($secretName)) {
            Write-Warning "Skipping empty line in the file."
            continue
        }

        # Debugging: Output the secret being checked
        Write-Output "Checking secret: $secretName"

        # Check if the secret exists in the Key Vault
        $secret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName -ErrorAction SilentlyContinue

        if ($null -ne $secret) {
            Write-Output "Secret '$secretName' exists in Key Vault '$keyVaultName'."
        } else {
            Write-Output "Secret '$secretName' does NOT exist in Key Vault '$keyVaultName'."
        }
    }
    catch {
        Write-Error "Error checking secret '$secretName': $_"
    }
}
