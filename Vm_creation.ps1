# =============================================
# USER CONFIGURATION - UPDATE THESE
# =============================================
$VMSubscriptionName     = ""                    # Subscription where VM is created
$VMResourceGroupName    = ""               # CHANGE: VM's RG
$VMName                 = ""                  # CHANGE: VM Name
$Location               = "eastus"
$Zone                   = "1"
$VMSize                 = "Standard_D4as_v4"

# VNet is in a DIFFERENT RG and SAME subscription
$VNetSubscriptionName   = ""
$VNetResourceGroupName   = ""
$VNetName               = ""
$SubnetName             = ""

$OSDiskType             = "StandardSSD_LRS"
$AdminUsername          = "localadmin"
$AdminPassword          = ""          # CHANGE & use Key Vault in prod



# Convert password
$SecurePassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($AdminUsername, $SecurePassword)

# --- Set Context to VM Subscription ---
Write-Host "Setting context to VM Subscription: $VMSubscriptionName" -ForegroundColor Cyan
Set-AzContext -Subscription $VMSubscriptionName -ErrorAction Stop | Out-Null

# --- Get VNet from different RG (same subscription) ---
Write-Host "Retrieving VNet from RG: $VNetResourceGroupName" -ForegroundColor Cyan
$VNet = Get-AzVirtualNetwork `
    -Name $VNetName `
    -ResourceGroupName $VNetResourceGroupName `
    -ErrorAction Stop

$Subnet = $VNet.Subnets | Where-Object { $_.Name -eq $SubnetName }
if (-not $Subnet) {
    Throw "Subnet '$SubnetName' not found in VNet '$VNetName'!"
}

# --- Create NIC in VM's RG, attached to remote subnet ---
$NIC = New-AzNetworkInterface `
    -Name "$VMName-nic" `
    -ResourceGroupName $VMResourceGroupName `
    -Location $Location `
    -SubnetId $Subnet.Id `
    -Force

Write-Host "NIC created: $($NIC.Name)" -ForegroundColor Green

# --- VM Configuration ---
$VM = New-AzVMConfig -VMName $VMName -VMSize $VMSize -Zone $Zone

$VM = Set-AzVMOperatingSystem `
    -VM $VM `
    -Windows `
    -ComputerName $VMName `
    -Credential $Credential `
    -ProvisionVMAgent `
    
$VM = Set-AzVMSourceImage `
    -VM $VM `
    -PublisherName "MicrosoftWindowsDesktop" `
    -Offer "windows-11" `
    -Skus "win11-25h2-pro" `
    -Version "latest"

$VM = Set-AzVMOSDisk `
    -VM $VM `
    -Name "$VMName-osdisk" `
    -StorageAccountType $OSDiskType `
    -CreateOption FromImage `
    -Caching ReadWrite

$VM = Add-AzVMNetworkInterface -VM $VM -Id $NIC.Id

$VM = Set-AzVMBootDiagnostic -VM $VM -Disable

# --- Deploy VM ---
Write-Host "Deploying VM '$VMName' in '$VMResourceGroupName' (Zone $Zone)..." -ForegroundColor Yellow
New-AzVM `
    -ResourceGroupName $VMResourceGroupName `
    -Location $Location `
    -VM $VM `
    -Verbose

Write-Host "`nVM '$VMName' deployed successfully!" -ForegroundColor Green
Write-Host "   Subscription: $VMSubscriptionName" -ForegroundColor Gray
Write-Host "   Resource Group: $VMResourceGroupName" -ForegroundColor Gray
Write-Host "   VNet (cross-RG): $VNetName in $VNetResourceGroupName" -ForegroundColor Gray
