$Private = @(Get-ChildItem -Path $PSScriptRoot/private -Recurse -Filter "*.ps1") | Sort-Object Name
$Public = @(Get-ChildItem -Path $PSScriptRoot/public -Recurse -Filter "*.ps1") | Sort-Object Name


foreach ($import in $Private) {
    try {
        . $import.fullName
        Write-Verbose -Message ("Imported private function {0}" -f $import.fullName)
    } catch {
        Write-Error -Message ("Failed to import private function {0}: {1}" -f $import.fullName, $_)
    }
}

foreach ($import in $Public) {
    try {
        . $import.fullName
        Write-Verbose -Message ("Imported public function {0}" -f $import.fullName)
    } catch {
        Write-Error -Message ("Failed to import public function {0}: {1}" -f $import.fullName, $_)
    }
}

Export-ModuleMember -Function $Public.BaseName