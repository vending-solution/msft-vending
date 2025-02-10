$ErrorActionPreference = "Stop"
$jsonRequestInput = '{"vending_support_team":"FOOID01","request_id":"auto-generated","global_id":"FOOID01","user_name":"FOOID01","contact_email_address":"requestor.owner@domain.com","aad_groups":{"owner":"xxxxx-xxxxx-xxxxx-xxxxx","reader":"zzzzz-zzzzz-zzzzz-zzzzz"},"tags":{"Application":"FOOID01","BusinessStream":"FOOID01","CostCenter":"BAR01"},"default_resource_groups":2,"subscriptions":[]}'
# Define the path of the folder
$workloadsDirectory = "C:\Users\luisape\repos\msft-vending\scripts\workloads"
$requestsDirectory = "$workloadsDirectory/requests"

# Create requests directory if not found
if (-Not (Test-Path -Path $requestsDirectory)) {
    # Create the folder if it does not exist
    New-Item -ItemType Directory -Path $requestsDirectory
    Write-Output "Folder created at $requestsDirectory"
}

# Validate request JSON against schema & parse
$requestSchema = Get-Content ../schemas/vending-request-schema.json -Raw
$jsonRequestInput | Test-Json -Schema $requestSchema
$jsonRequest = $jsonRequestInput | ConvertFrom-Json
$requestId = $jsonRequest.global_id

# Save request to file
$requestDirectory = "$requestsDirectory/$requestId"
$requestFile = "$requestDirectory/request.json"

# Create request directory if not found
if (-Not (Test-Path -Path $requestDirectory)) {
    # Create the folder if it does not exist
    New-Item -ItemType Directory -Path $requestDirectory
    Write-Output "Folder created at $requestDirectory"
}
            
# Should this delete the builds/subscriptions directories?
# Delete existing JSON request
if (Test-Path $requestFile) {
    Remove-Item $requestFile -Force
}

# Save new request JSON file
New-Item $requestFile -ItemType File -Value $jsonRequest