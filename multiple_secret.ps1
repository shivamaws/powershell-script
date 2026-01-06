# Login
Connect-AzAccount

# List of App Object IDs
$appObjectIds = @(
    "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy",
    "zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz"
)

# Expiry for new secrets (example: 1 year from today)
$endDate = (Get-Date).AddYears(1)

# Create empty array for output
$results = @()

foreach ($objId in $appObjectIds) {
    # Get the application object
    $app = Get-AzADApplication -ObjectId $objId

    # Generate new client secret
    $secret = New-AzADAppCredential -ObjectId $objId -EndDate $endDate

    # Prepare output
    $results += [PSCustomObject]@{
        DisplayName = $app.DisplayName
        ClientId    = $app.AppId
        SecretId    = $secret.KeyId
        SecretValue = $secret.SecretText  # <-- NOTE: only available right after creation
        EndDate     = $secret.EndDate
    }
}

# Show output in table
$results | Format-Table -AutoSize

# Export to CSV if needed
$results | Export-Csv -Path "ClientSecrets.csv" -NoTypeInformation
