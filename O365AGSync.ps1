# Define the URL of the web virtual directory
$webUrl = "http://example.com/virtualdirectory/"

# Define the local directory where files will be saved
$localDir = "C:\path\to\download\directory"

# Create the local directory if it doesn't exist
if (-not (Test-Path -Path $localDir)) {
    New-Item -ItemType Directory -Path $localDir
}

# Download the files from the web virtual directory
$webClient = New-Object System.Net.WebClient

# Log file for the download process
$logFile = Join-Path $localDir "download_log.txt"

# Get the list of files in the web virtual directory
$files = Invoke-WebRequest -Uri $webUrl -UseBasicParsing

# Initialize log file
Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Starting download process"

# Download each file
foreach ($file in $files.Links) {
    $fileUrl = $file.href
    $fileName = [System.IO.Path]::GetFileName($fileUrl)
    $localFilePath = Join-Path $localDir $fileName

    try {
        $webClient.DownloadFile($fileUrl, $localFilePath)
        Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Successfully downloaded $fileName from $fileUrl to $localFilePath"
    } catch {
        Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Failed to download $fileName from $fileUrl. Error: $_"
    }
}

$webClient.Dispose()
Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Download process complete"

Write-Output "Download complete! Check the log file at $logFile for details."
