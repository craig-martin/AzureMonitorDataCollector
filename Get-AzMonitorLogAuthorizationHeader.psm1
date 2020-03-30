function Get-AzMonitorLogAuthorizationHeader {
    <#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    Example of how to use this cmdlet
.EXAMPLE    
    Get-AzMonitorLogAuthorizationHeader -WorkspaceId bd18b307-5593-4244-b922-615e226a0325 -WorkspaceKey aSBsb3ZlIGJpa2Vz -JsonBody "{foo: 'bar'}" -RequestDate (Get-Date)
#>
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter(Mandatory=$true)]
        [Guid]$WorkspaceId,
        [Parameter(Mandatory=$true)]
        [String]$WorkspaceKey,
        [Parameter(Mandatory=$true)]
        [DateTime]$RequestDate,
        [Parameter(Mandatory=$true)]
        [String]$JsonBody
    )
    # The date that the request was processed, in RFC 1123 format.
    $xHeaders = "x-ms-date:" + $RequestDate.ToString("r")
    $contentType = 'application/json'
    $resource = '/api/logs'
    $stringToHash = 'POST' + "`n" + $JsonBody.Length + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($WorkspaceKey)

    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $WorkspaceId, $encodedHash
    
    Write-Output $authorization
}
