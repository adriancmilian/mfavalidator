Begin {
    Start-Transcript -Path ".\transcript.txt"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
    Import-Module ./mfavalidator -force

    $secret = ''
    $tenantid = ''
    $clientid = ''
    $scope = "https://graph.microsoft.com/.default"
    $url = "https://login.microsoftonline.com/$tenantid/oauth2/v2.0/token"
    $body = @{
        'scope'         = $scope
        'grant_type'    = 'client_credentials'
        'client_id'     = $clientid
        'client_secret' = $secret
    }
    $params = @{
        'ContentType' = 'application/x-www-form-urlencoded'
        'Method'      = 'POST'
        'Body'        = $body
        'Uri'         = $url
    }
    $accessToken = (Invoke-RestMethod @params).access_token
    $authHeader = @{
        "Content-Type"     = "application/json"
        "Authorization"    = "Bearer $accessToken"
        "ConsistencyLevel" = "eventual"
    }

    $users = Get-AllEnabledMgUsers -authheader $authHeader
    $usersMfaStatus = Get-UsersMFAStatus -userList $users -authheader $authHeader
    $usersToFlagEnabled = Get-EnabledMfaUsersCustomSecAttributes -userList $usersMfaStatus.mfaenabled -authheader $authHeader
    $usersToFlagDisabled = (Get-DisabledMfaUsersCustomSecAttributes -authheader $authHeader -userList $usersMfaStatus.mfadisabled).split('', [System.StringSplitOptions]::RemoveEmptyEntries)
    $cloudOnlyAccounts = [System.Collections.Generic.List[string]]::new()
    $disabledAccounts = [System.Collections.Generic.List[string]]::new()
}


Process {
    if ($usersToFlagEnabled) {
        Set-UserFlagsWithMFAEnabled -userList $usersToFlagEnabled -authheader $authHeader
    }

    if ($usersToFlagDisabled) {
        Set-UserFlagsWithMFADisabled -userList $usersToFlagDisabled -authheader $authHeader
    }

    if ($usersMfaStatus.mfadisabled) {
        $usersToDisable = Get-MgUserToDisable -authheader $authHeader -userList $usersMfaStatus.mfadisabled.split('', [System.StringSplitOptions]::RemoveEmptyEntries)
    }
    
    if ($usersToDisable) {
        Write-Verbose "Disabling users..."
        foreach ($user in $usersToDisable) {
            $samaccountname = Get-SamAccountName -authheader $authHeader -userid $user
            if ($samaccountname) {
                Disable-ADAccount -Identity $samaccountname
                $disabledAccounts.Add($user)
            }
            else {
                Write-Warning "No on-prem samaccountname found for user $user"
                $cloudOnlyAccounts.Add($user)
            }
        }
        Disable-MgUser -userList $cloudOnlyAccounts -authheader $authHeader
        Clear-CustomSecAttributes -userList $disabledAccounts -authheader $authHeader
    }
}

End {
    Stop-Transcript
}