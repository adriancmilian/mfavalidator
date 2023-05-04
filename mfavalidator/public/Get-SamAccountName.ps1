function Get-SamAccountName {
    [cmdletbinding()]
    Param(
    [Parameter(Mandatory)]
    [hashtable]$authheader,
    [Parameter(Mandatory)]
    [string]$userid
    )

    Begin {
        $uri = "https://graph.microsoft.com/beta/users/$userid"
        $selectProperties = '$select=onPremisesSamAccountName'
    }

    Process {
        try {
            $resp = Invoke-RestMethod -Method Get -Uri "$($uri)?$selectProperties" -Headers $authHeader
        }
        catch {
            Write-Error $_
        }
    }

    End {
        return $resp.onPremisesSamAccountName
    }
}