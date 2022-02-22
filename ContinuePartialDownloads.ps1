#requires -Version 7
$ariaExeLocation = "C:\Program Files\Native Instruments\Native Access\aria2c.exe"
$downloadLocation = Join-Path -Path $env:USERPROFILE -ChildPath "Downloads"
$metaLinksLocation = "C:\.native-instruments.tmp\"
$ProgressPreference = "SilentlyContinue"

Write-Host -ForegroundColor Cyan ">>> Checking partially downloaded files..."
$cores = (Get-ComputerInfo).CsNumberOfLogicalProcessors
$partiallyDownloadedFiles = Get-ChildItem -Path $metaLinksLocation -Filter "*.meta4" | ForEach-Object -ThrottleLimit $cores -Parallel {
    [xml]$content = Get-Content -Path $_.FullName
    $expectedHash = ($content.metalink.file.hash | Where-Object { $_.type -eq "md5" }).InnerText
    $actualHash = (Get-FileHash -Algorithm "MD5" -Path (Join-Path -Path $using:downloadLocation -ChildPath $content.metalink.file.Attributes["name"].Value) -ErrorAction "SilentlyContinue").Hash
    if($actualHash -ne $expectedHash) {
        Write-Host "Adding $($content.metalink.file.Attributes['name'].Value) to download queue"
        return @{
            Name = $content.metalink.file.Attributes["name"].Value
            Path = $_.FullName
            Size = [long]$content.metalink.file.size
        }
    } else {
        Write-Host -ForegroundColor DarkGray "$($content.metalink.file.Attributes['name'].Value) is already complete"
    }
} | Sort-Object { $_.Size }

Write-Host -ForegroundColor Cyan "`n>>> Kicking off $($partiallyDownloadedFiles.Length) incomplete Native Instrument downloads"

$partiallyDownloadedFiles | ForEach-Object -ThrottleLimit 5 -Parallel {
    Write-Host -ForegroundColor Cyan "`n>>> Downloading file '$($_.Name)'"
    $duration = Measure-Command {
        Start-Process -NoNewWindow -Wait -FilePath $using:ariaExeLocation -ArgumentList  @(
            "--no-conf=true",
            "--connect-timeout=10",
            "--timeout=10",
            "--max-tries=1",
            "--retry-wait=0",
            "--dir=$using:downloadLocation",
            "--file-allocation=none",
            "--console-log-level=warn",
            "--summary-interval=0",
            "--quiet"
            "--max-connection-per-server=10", # this is the one that does the magic
            $_.Path
        )
    }
    Write-Host "Completed in $($duration.Minutes) minutes"
}