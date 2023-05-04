function Set-UserFlagsWithMFADisabled {
    [cmdletbinding()]
    param (
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
        $attset = @{
            "customSecurityAttributes" = @{            
                "mfaregistration" = @{
                    "@odata.type" = "#Microsoft.DirectoryServices.CustomSecurityAttributeValue" 
                    "mfaenabled"  = $false
                    "dateflagged" = [string](Get-Date -Format "yyyy-MM-dd")
                }
            }
        }
        $headers = @{
            "Content-Type" = "application/json"
        }
    }

    Process {
        while ($i -le $userCount) {
            if ($batchRequest.requests.Count -eq 20) {

                Try {
                    $params = @{
                        "Uri"     = $uri
                        "Method"  = "POST"
                        "Body"    = ($batchRequest | ConvertTo-Json -Depth 5)
                        "Headers" = $authHeader
                    }
                    $resp = Invoke-RestMethod @params
                    if ($resp.responses.status -contains 429) {
                        $sleep = $resp.responses.headers.'retry-after'[0] -as [int]
                        Start-Sleep -Seconds $sleep
                        $resp = Invoke-RestMethod @params
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
                        "Uri"     = $uri
                        "Method"  = "POST"
                        "Body"    = ($batchRequest | ConvertTo-Json -Depth 5)
                        "Headers" = $authHeader
                    }
                    $resp = Invoke-RestMethod @params
                    if ($resp.responses.status -contains 429) {
                        $sleep = $resp.responses.headers.'retry-after'[0] -as [int]
                        Start-Sleep -Seconds $sleep
                        $resp = Invoke-RestMethod @params
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
                            "id"      = $x
                            "method"  = "PATCH"
                            "url"     = "users/$($userList[$i])"
                            "body"    = $attset
                            "headers" = $headers
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
                        "id"      = $x
                        "method"  = "PATCH"
                        "url"     = "users/$($userList[$i])"
                        "body"    = $attset
                        "headers" = $headers
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

    }
    
}