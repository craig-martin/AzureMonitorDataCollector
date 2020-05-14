Function Send-OMSAPIIngestionFile
{
    <#
.SYNOPSIS
    Sends the json payload securely to a customer workspace leveraging a
    customer ID and shared key
.DESCRIPTION
    Leveraging a customer workspaceID and private key for Log Analytics
    this function will send a json payload securely to the OMS ingestion
    API for indexing
.PARAMETER customerId
    The customer workspace ID that can be found within the settings pane of the
    OMS workspace.
.PARAMETER sharedKey
    The primary or secondary private key for the customer OMS workspace 
    found within the same view as the workspace ID within the settings pane
.PARAMETER body
    json payload
.PARAMETER logType
    Name of log to be ingested assigned to JSON payload
    (will have "_CL" appended upon ingestion)
.PARAMETER TimeStampField
    Time data was ingested.  If $TimeStampField is defined for JSON field
    when calling this function, ingestion time in Log Analytics will be 
    associated with that field.

    example: $Timestampfield = "Timestamp" 

    foreach($metricValue in $metric.MetricValues)
    {
        $sx = New-Object PSObject -Property @{
            Timestamp = $metricValue.Timestamp.ToString()
            MetricName = $metric.Name; 
            Average = $metricValue.Average;
            SubscriptionID = $Conn.SubscriptionID;
            ResourceGroup = $db.ResourceGroupName;
            ServerName = $SQLServer.Name;
            DatabaseName = $db.DatabaseName;
            ElasticPoolName = $db.ElasticPoolName
        }
        $table = $table += $sx
    }
    Send-OMSAPIIngestionFile -customerId $customerId -sharedKey $sharedKey`
     -body $jsonTable -logType $logType -TimeStampField $Timestampfield

.PARAMETER EnvironmentName
    If $EnvironmentName is defined for AzureUSGovernment
    when calling this function, ingestion will go to an Azure Government Log Analytics
    workspace.  Otherwise, Azure Commercial endpoint is leveraged by default.
#>
    Param
    (
        [Parameter(Mandatory = $True)]$customerId,
        [Parameter(Mandatory = $True)]$sharedKey,
        [Parameter(Mandatory = $True)]$body,
        [Parameter(Mandatory = $True)]$logType,
        [Parameter(Mandatory = $False)]$TimeStampField,
        [Parameter(Mandatory = $False)]$EnvironmentName
    )

    #<KR> - Added to encode JSON message in UTF8 form for double-byte characters
    $body=[Text.Encoding]::UTF8.GetBytes($body)
    
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $body.Length
    $signature = Get-OMSAPISignature `
     -customerId $customerId `
     -sharedKey $sharedKey `
     -date $rfc1123date `
     -contentLength $contentLength `
     -method $method `
     -contentType $contentType `
     -resource $resource
    if($EnvironmentName -eq "AzureUSGovernment")
    {
        $Env = ".ods.opinsights.azure.us"
    }
    Else
    {
        $Env = ".ods.opinsights.azure.com"
    }
    $uri = "https://" + $customerId + $Env + $resource + "?api-version=2016-04-01"
    if ($TimeStampField.length -gt 0)
    {
        $headers = @{
            "Authorization" = $signature;
            "Log-Type" = $logType;
            "x-ms-date" = $rfc1123date;
            "time-generated-field"=$TimeStampField;
        }
    }
    else {
         $headers = @{
            "Authorization" = $signature;
            "Log-Type" = $logType;
            "x-ms-date" = $rfc1123date;
        }
    } 
    $response = Invoke-WebRequest `
        -Uri $uri `
        -Method $method `
        -ContentType $contentType `
        -Headers $headers `
        -Body $body `
        -UseBasicParsing
    
    if ($response.StatusCode -ge 200 -and $response.StatusCode -le 299)
    {
        write-output 'Accepted'
    }
}