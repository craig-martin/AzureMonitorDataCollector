Function Get-OMSAPISignature
{
    <#
.SYNOPSIS
    Builds an OMS authorization to securely communicate to a customer workspace.
.DESCRIPTION
    Leveraging a customer workspaceID and private key for Log Analytics
    this function will build the necessary api signature to securely send
    json data to the OMS ingestion API for indexing
.PARAMETER customerId
    The customer workspace ID that can be found within the settings pane of the
    OMS workspace.
.PARAMETER sharedKey
    The primary or secondary private key for the customer OMS workspace 
    found within the same view as the workspace ID within the settings pane
.PARAMETER date
    RFC 1123 standard UTC date string converted variable used for ingestion time stamp
.PARAMETER contentLength
    Body length for payload being sent to the ingestion endpoint
.PARAMETER method
    Rest method used (POST)
.PARAMETER contentType
    Type of data being sent in the payload to the endpoint (application/json)
.PARAMETER resource
    Path to send the logs for ingestion to the rest endpoint
.EXAMPLE
    Get-OMSAPISignature -customerId bd18b307-5593-4244-b922-615e226a0325 -sharedKey aSBsb3ZlIGJpa2Vz -date 12/31/1999 -contentLength "{foo: 'bar'}".Length -method POST -contentType application/json -resource /api/logs
#>
    Param
    (
        [Parameter(Mandatory = $True)]$customerId,
        [Parameter(Mandatory = $True)]$sharedKey,
        [Parameter(Mandatory = $True)]$date,
        [Parameter(Mandatory = $True)]$contentLength,
        [Parameter(Mandatory = $True)]$method,
        [Parameter(Mandatory = $True)]$contentType,
        [Parameter(Mandatory = $True)]$resource
    )
    Get-AzMonitorLogAuthorizationHeader -WorkspaceId $customerId -WorkspaceKey $sharedKey -JsonBodyLength $contentLength -RequestDate $date
}