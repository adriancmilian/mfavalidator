function Get-AllEnabledMgUsers {
    <#
    .SYNOPSIS
    Get's all users that are enabled in the 365 tenant using the REST api
    #>
    [cmdletbinding()]
    Param(
    [Parameter(Mandatory)]
    [hashtable]$authheader
    )

    Begin {
        $users = [System.Collections.Generic.List[string]]::new()
        $uri = "https://graph.microsoft.com/beta/users"
        $enabledFilter = "`$filter=accountEnabled eq true and assignedLicenses/`$count ne 0&`$count=true"
        $selectProperties = '$select=id,'
    }

    Process {
        $resp = Invoke-RestMethod -Method Get -Uri "$($uri)?$enabledFilter&$selectProperties" -Headers $authHeader
        $users.Add($resp.value.id)
        $nextpage = $resp.'@odata.nextLink'


        # Goes through each page provided by the api response and stores the users in the users list
        while ($nextpage) {
            $resp = Invoke-RestMethod -Method Get -Uri $nextpage -Headers $authHeader
            $users.Add($resp.value.id)
            $nextpage = $resp.'@odata.nextLink'
        }
    }

    End {
        $userList = $users.Split()
        return $userList
    }
}