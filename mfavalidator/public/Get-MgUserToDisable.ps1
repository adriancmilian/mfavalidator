function Get-MgUserToDisable {
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory)]
        [array]$userList,
        [Parameter(Mandatory)]
        [hashtable]$authheader
    )

    Begin {
        $uri = "https://graph.microsoft.com/beta/`$batch"
        $userCount = $userList.Count
        $i = 0
        $batchRequest = $null
        $usersToDisable = [System.Collections.Generic.List[string]]::new()
    }
    Process {
        while ($i -le $userCount) {
            if ($batchRequest.requests.Count -eq 20) {

                Try {
                    $params = @{
                        "Uri" = $uri
                        "Method" = "POST"
                        "Body" = ($batchRequest | ConvertTo-Json)
                        "Headers" = $authHeader
                    }
                    $resp = Invoke-RestMethod @params
                    if ($resp.responses.status -contains 429) {
                        $sleep = $resp.responses.headers.'retry-after'[0] -as [int]
                        Start-Sleep -Seconds $sleep
                        $resp = Invoke-RestMethod @params
                    }
                    foreach ($response in $resp.responses) {
                        $mfaStatus = $response.body.customSecurityAttributes.mfaregistration.mfaenabled
                        $dateFlagged = $response.body.customSecurityAttributes.mfaregistration.dateflagged
                        $dateDiff = ((Get-Date) - (Get-Date $dateFlagged))
                        if (!$mfaStatus -and $dateDiff.Days -ge 7) {
                            $usersToDisable.Add(($response.body.Id))
                        }
                    }
                }

                Catch {
                    Write-Error $_
                } 
                # Create empty json batch
                finally {
                    Write-Verbose "Clearing batch request to create new one..."
                    $batchRequest = $null
                }
            }

            # Performs the final json batch request
            elseif ($i % 20 -gt 0) {
                Try {
                    $params = @{
                        "Uri" = $uri
                        "Method" = "POST"
                        "Body" = ($batchRequest | ConvertTo-Json)
                        "Headers" = $authHeader
                    }
                    $resp = Invoke-RestMethod @params
                    if ($resp.responses.status -contains 429) {
                        $sleep = $resp.responses.headers.'retry-after'[0] -as [int]
                        Start-Sleep -Seconds $sleep
                        $resp = Invoke-RestMethod @params
                    }
                    foreach ($response in $resp.responses) {
                        $mfaStatus = $response.body.customSecurityAttributes.mfaregistration.mfaenabled
                        $dateFlagged = $response.body.customSecurityAttributes.mfaregistration.dateflagged
                        $dateDiff = ((Get-Date) - (Get-Date $dateFlagged))
                        if (!$mfaStatus -and $dateDiff.Days -ge 7) {
                            $usersToDisable.Add(($response.body.Id))
                        }
                    }
                    $i++
                }

                Catch {
                    Write-Error $_
                } 
                # Create empty json batch
                finally {
                    Write-Verbose "Clearing batch request to create new one..."
                    $batchRequest = $null
                }
            }

            # Creates batch request if less then 20 users remain
            elseif (($userCount - $i) -lt 20) {
                $request_list = [System.Collections.Generic.List[Object]]::new()
                $remainder = $userCount - $i
                if ($remainder -eq 0) {
                    $i++
                }
                else {
                    for ($x = 1; $x -lt ($remainder + 1); $x++) {
                        $request = [pscustomobject][ordered]@{
                            "id"     = $x
                            "method" = "GET"
                            "url"    = "users/$($userList[$i])?`$select=customSecurityAttributes,Id"
                        }
                        $request_list.Add($request)
                        $i++
                    }
                    $batchRequest = [pscustomobject][ordered]@{
                        requests = $request_list
                    }
                }
            }

            # Creates a batch request of 20 requests
            else {
                $request_list = [System.Collections.Generic.List[Object]]::new()
                for ($x = 1; $x -lt 21; $x++) {
                    $request = [pscustomobject][ordered]@{
                        "id"     = $x
                        "method" = "GET"
                        "url"    = "users/$($userList[$i])?`$select=customSecurityAttributes,Id"
                    }
                    $request_list.Add($request)
                    $i++
                }
                $batchRequest = [pscustomobject][ordered]@{
                    requests = $request_list
                }
            }
        }
    }
    End {
        Return $usersToDisable
    }
}