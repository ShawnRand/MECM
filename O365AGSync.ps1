#####################################################################################################
# Requires WebClient object $webClient defined, e.g. $webClient = New-Object System.Net.WebClient
# Parameters:
#   $source      - The url of folder to copy, with trailing /, e.g. http://website/folder/structure/
#   $destination - The folder to copy $source to, with trailing \ e.g. D:\CopyOfStructure\
#   $recursive   - True if subfolders of $source are also to be copied or False to ignore subfolders
#   $logsfolder - dir to put the logs
#   $cleanupdays - number of days to keep content should be >30
#   Return       - None
# IIS default website add virtual dir, add feature dir browsing, add mime type .dat
#####################################################################################################

$webClient = New-Object System.Net.WebClient
$source = "http://MECM01.RandLab.az/O365Updates/"
$destination = "F:\Office365AGSync\O365Content\"
$logsfolder = "F:\Office365AGSync\Logs"
$recursive = $true
$cleanupdays = 45

# Define the path to the log file
$logFile = Join-Path $logsfolder "Office365MPESync.log"

# Create $logsfolder directory if it doesn't exist
if (-not (Test-Path -Path $logsfolder)) {
    New-Item -ItemType Directory -Path $logsfolder
}
# Create $destination directory if it doesn't exist
if (-not (Test-Path -Path $destination)) {
    New-Item -ItemType Directory -Path $destination
}

# Initialize log file
if (-not (Test-Path -Path $logFile)) {
    New-Item -ItemType File -Path $logFile
}

# Function to log messages
function Log-Message {
    param (
        [string]$Message
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$Timestamp - $Message"
    Add-Content -Path $logFile -Value $LogEntry
}

Log-Message "Starting download process"

function Copy-Folder {
    param (
        [string]$source,
        [string]$destination,
        [bool]$recursive
    )
    if (-not (Test-Path -Path $destination)) {
        New-Item $destination -ItemType Directory -Force
        Log-Message "Created directory: $destination"
    }
    # Get the file list from the web page
    $webString = $webClient.DownloadString($source)
    $lines = [Regex]::Split($webString, "<br>")

    # Parse each line, looking for files and folders
    foreach ($line in $lines) {
        if ($line.ToUpper().Contains("HREF")) {
            # File or Folder
            if (!$line.ToUpper().Contains("[TO PARENT DIRECTORY]")) {
                # Not Parent Folder entry
                $items = [Regex]::Split($line, """")
                $items = [Regex]::Split($items[2], "(>|<)")
                $item = $items[2]
                if ($line.ToLower().Contains("&lt;dir&gt")) {
                    # Folder
                    if ($recursive) {
                        # Subfolder copy required
                        Log-Message "Entering directory: $item"
                        Copy-Folder "$source$item/" "$destination$item/" $recursive
                    }
                } else {
                    # File
                    $destFile = "$destination$item"
                    if (-not (Test-Path -Path $destFile)) {
                        try {
                            $webClient.DownloadFile("$source$item", $destFile)
                            Log-Message "Successfully downloaded $item to $destination"
                        } catch {
                            Log-Message "Failed to download $item from $source$item. Error: $_"
                        }
                    } else {
                        Log-Message "File already exists: $destFile"
                    }
                }
            }
        }
    }
}

function Cleanup {
    param (
        [string]$FolderPath,
        [int]$cleanupdays
    )
    if (Test-Path $FolderPath) {
        Log-Message "Folder exists: $FolderPath"

        # Get the contents of the folder
        $FolderContents = Get-ChildItem $FolderPath

        # Iterate through each item in the folder
        foreach ($Item in $FolderContents) {
            # Calculate the item's age in days
            $ItemAge = (Get-Date) - $Item.LastWriteTime

            # Check if the item is older than specified days
            if ($ItemAge.Days -gt $cleanupdays) {
                # Delete the item
                Remove-Item $Item.FullName -Recurse -Force
                Log-Message "Deleted: $($Item.FullName)"
            } else {
                Log-Message "Retained: $($Item.FullName) (Age: $($ItemAge.Days) days)"
            }
        }
    } else {
        Log-Message "The folder does not exist."
    }
    Log-Message "Cleanup completed."
}

# Start the download process
Copy-Folder $source $destination $recursive
Log-Message "Download process complete"

# Start the cleanup process
Cleanup $destination $cleanupdays

Log-Message "Script completed."
