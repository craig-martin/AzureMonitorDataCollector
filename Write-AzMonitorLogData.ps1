function Write-AzMonitorLogData {
    <#
.SYNOPSIS
    Sends json securely to an Azure Monitor Log Analytics workspace using a workspace ID and shared key
.DESCRIPTION
    Long description
.EXAMPLE
    ### Pipe objects into Log Analytics
    @(
    [PSCustomObject]@{
        Name = 'foo'
        Number = 8675309
    },
    [PSCustomObject]@{
        Name = 'bar'
        Number = 5555309
    }
    ) | Write-AzMonitorLogData -LogType PhoneLogs -WorkspaceId bd18b307-5593-4244-b922-615e226a0325 -WorkspaceKey aSBsb3ZlIGJpa2Vz -Verbose

.EXAMPLE
    ### [TODO - this does not work right now] Write a simple object to Log Analytics 
    Write-AzMonitorLogData -WorkspaceId bd18b307-5593-4244-b922-615e226a0325 -WorkspaceKey 'aSBsb3ZlIGJpa2Vz' -JsonBody "[{foo: 'bar'}]" -LogType FooLog
#>
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter(Mandatory=$true)]
        [Guid]$WorkspaceId,
        [Parameter(Mandatory=$true)]
        [String]$WorkspaceKey,
        [Parameter(Mandatory=$true)]
        [String]$LogType,        
        [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [object]$InputObject,
        [Parameter(Mandatory=$false)]
        [String]$JSON,
        [Parameter(Mandatory = $False)]
        $EnvironmentName = "AzurePublic"
    )
    process{
        if($EnvironmentName -eq "AzureUSGovernment")
        {
            $Env = ".ods.opinsights.azure.us"
        }
        Else
        {
            $Env = ".ods.opinsights.azure.com"
        }

        $resource = '/api/logs'
        $requestDate = [DateTime]::UtcNow
        $rfc1123date = $requestDate.ToString("r")
            
        $uri = "https://" + $WorkspaceId + $Env + $resource + "?api-version=2016-04-01"

        if ($InputObject) {$jsonBody = $InputObject | ConvertTo-Json -Depth 100}
        if ($JSON) {$jsonBody = $JSON}
    
        Write-Verbose "  JSON body length: $($jsonBody.Length)"
        $signature = Get-AzMonitorLogAuthorizationHeader -WorkspaceId $WorkspaceId -WorkspaceKey $WorkspaceKey -JsonBodyLength $jsonBody.Length -RequestDate $requestDate
        $headers = @{
            "Authorization"        = $signature;
            "Log-Type"             = $LogType;
            "x-ms-date"            = $rfc1123date;
            #"time-generated-field" = $TimeStampField;
        }
        
        $retry = 0
        $uploadSuccess = $false
        do
        {
            $retry++
            
            try{
                $response = Invoke-WebRequest -Uri $uri -Method Post -ContentType 'application/json' -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($JsonBody)) -UseBasicParsing
        
                Write-Verbose "Received Status: $($response.StatusCode)"

                if ($response.StatusCode -eq 200)
                {
                    $uploadSuccess = $true
                }
                else
                {
                    Write-Warning "  Failed to write to Log Analytics: $($response.StatusCode)"
                }
            }
            catch{
                Write-Warning "  Failed to write to Log Analytics: $_"
            }
        }
        until ($retry -eq 3 -or $response.StatusCode -eq 200)   
        
        if ($uploadSuccess -eq $false)
        {
            Write-Error -Message 'Failed to write to log analytics' -Category WriteError -TargetObject $jsonBody
        }     
    }    
}