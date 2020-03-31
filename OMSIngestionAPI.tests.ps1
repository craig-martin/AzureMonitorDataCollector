#Requires -Modules @{ ModuleName="pester"; RequiredVersion="4.10.1" }

Describe 'OMSIngestionAPI Module' {
    It 'Should not throw when imported ' {   
        {
        Import-Module -Name OMSIngestionAPI } |
    Should Not Throw        
    }   

    It 'Should be loaded' {   
        Get-Module -Name OMSIngestionAPI |
    Should Not Be $null        
    }

    It 'Exports Get-OMSAPISignature' {           
        Get-Command -Name Get-OMSAPISignature -Module OMSIngestionAPI |
    Should Not Be $null        
    }

    It 'Exports Send-OMSAPIIngestionFile' {           
        Get-Command -Name Send-OMSAPIIngestionFile -Module OMSIngestionAPI |
    Should Not Be $null        
    }
}

Describe 'Get-OMSAPISignature Function' {
    $sampleObjectJson = Get-Date 12/31/1999 | ConvertTo-Json
    $sampleObjectJsonBytes = [Text.Encoding]::UTF8.GetBytes($sampleObjectJson)

    It 'Should not throw with good input' {
        {
        Get-OMSAPISignature -customerId foo -sharedKey aSBsb3ZlIGJpa2Vz -date ([DateTime]::Now) -contentLength $sampleObjectJsonBytes.Length -method POST -contentType application/json -resource /api/logs} | 
    Should Not Throw        
    }   
 
    It 'Return a string with good input' {
        Get-OMSAPISignature -customerId foo -sharedKey aSBsb3ZlIGJpa2Vz -date ([DateTime]::Now) -contentLength $sampleObjectJsonBytes.Length -method POST -contentType application/json -resource /api/logs | 
    Should Not Be $null        
    }

    It 'Return expected string with known input' {
        Get-OMSAPISignature -customerId foo -sharedKey aSBsb3ZlIGJpa2Vz -date 12/31/1999 -contentLength $sampleObjectJsonBytes.Length -method POST -contentType application/json -resource /api/logs | 
    Should Be 'SharedKey foo:E2Q3Q5Qere09KJcRw5AAEdV4R8U3CrA/fem+FJOQdXw='
    }   
}

<#
Import-Module -Name OMSIngestionAPI
Invoke-Pester -Script OMSIngestionAPI.tests.ps1 -TestName 'Send-OMSAPIIngestionFile Function'
#>



 Describe 'Write-AzMonitorLogData Function' {
    InModuleScope OMSIngestionAPI {
        Mock -CommandName Invoke-WebRequest -ModuleName OMSIngestionAPI -MockWith { 
            return [PSCustomObject]@{
                StatusCode       = 200
            }
        } -Verifiable
        
        It 'Should not throw with good input' {                  
            {                
                Write-AzMonitorLogData -LogType PhoneLogs -WorkspaceId bd18b307-5593-4244-b922-615e226a0325 -WorkspaceKey aSBsb3ZlIGJpa2Vz -Verbose -InputObject (Get-Date 12/31/1999)
            } |
            Should Not Throw                 
        }
        <#
        It 'Return Nothing with good input' {                  
            Get-Date 12/31/1999 | Write-AzMonitorLogData -LogType PhoneLogs -WorkspaceId bd18b307-5593-4244-b922-615e226a0325 -WorkspaceKey aSBsb3ZlIGJpa2Vz -Verbose  |
            Should Be $null          
        }
        #>
    }
}
    
    

Describe 'Send-OMSAPIIngestionFile Function' {
    InModuleScope OMSIngestionAPI {
    Mock -CommandName Invoke-WebRequest -MockWith { 
        return [PSCustomObject]@{
            StatusCode       = 200
        }
    } -Verifiable

    $sampleObjectJson = Get-Process -Name System | ConvertTo-Json
    
    It 'Should not throw with good input' {                  
        {
            Send-OMSAPIIngestionFile -customerId foo -sharedKey aSBsb3ZlIGJpa2Vz -body $sampleObjectJson -logType fooLog
            Assert-MockCalled -CommandName Invoke-WebRequest
        } |
        Should Not Throw                 
    }

    It 'Return "Accepted" with good input' {                  
        Send-OMSAPIIngestionFile -customerId foo -sharedKey aSBsb3ZlIGJpa2Vz -body $sampleObjectJson -logType fooLog |
        Should Be 'Accepted'          
    }
}
}


Describe 'Get-AzMonitorLogAuthorizationHeader' {
    It 'Should not throw with good input' {
        {
            Get-AzMonitorLogAuthorizationHeader -WorkspaceId bd18b307-5593-4244-b922-615e226a0325 -WorkspaceKey aSBsb3ZlIGJpa2Vz -JsonBody "{foo: 'bar'}" -RequestDate (Get-Date) 
        } | 
    Should Not Throw        
    }   
 
    It 'Return a string with good input' {
        Get-AzMonitorLogAuthorizationHeader -WorkspaceId bd18b307-5593-4244-b922-615e226a0325 -WorkspaceKey aSBsb3ZlIGJpa2Vz -JsonBody "{foo: 'bar'}" -RequestDate (Get-Date) | 
    Should Not Be $null        
    }

    It 'Return expected string with known input' {
        Get-AzMonitorLogAuthorizationHeader -WorkspaceId bd18b307-5593-4244-b922-615e226a0325 -WorkspaceKey aSBsb3ZlIGJpa2Vz -JsonBody "{foo: 'bar'}" -RequestDate 12/31/1999 | 
    Should Be 'SharedKey bd18b307-5593-4244-b922-615e226a0325:Xo4Gzp/DmUzINl0nPfTtmg7eCsqSqpaMR7lsR9+z6Wc='
    }   
}
