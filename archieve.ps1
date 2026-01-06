# Login to Azure Account

Connect-AzAccount
 
# Define parameters

$subscriptionId = "yourSubscriptionId"

$resourceGroupName = "yourResourceGroupName"

$storageAccountName = "yourStorageAccountName"

$containerName = "yourContainerName"
 
# Select the specific subscription

Select-AzSubscription -SubscriptionId $subscriptionId
 
# Get the storage account context

$storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName

$ctx = $storageAccount.Context
 
# Get the list of blobs in the container

$blobs = Get-AzStorageBlob -Container $containerName -Context $ctx
 
# Loop through each blob and set the access tier to Archive

foreach ($blob in $blobs) {

    $blobRef = [Microsoft.Azure.Storage.Blob.CloudBlockBlob]::new((New-Object Microsoft.Azure.Storage.StorageUri([Uri]::new($blob.ICloudBlob.Uri.AbsoluteUri))), $ctx.Credentials)

    $blobRef.SetStandardBlobTier([Microsoft.Azure.Storage.Blob.StandardBlobTier]::Archive)

    Write-Output "Changed access tier of blob $($blob.Name) to Archive.
