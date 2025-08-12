# Update a game from a GitHub repository
function UpdateGame {

    # Script takes parameters, the github repo of the game, and the path to the game folder.
    param (
        [string]$RepoOwner,
        [string]$RepoName,
        [string]$GameFolder
    )

    # Create the game folder if it does not exist
    if (-not (Test-Path -Path $GameFolder)) {
        Write-Host "Game folder does not exist. Creating folder at $GameFolder..."
        New-Item -ItemType Directory -Path $GameFolder | Out-Null
    }

    # Create a temporary file called VERSION if it does not exist
    $versionFilePath = Join-Path -Path $GameFolder -ChildPath "VERSION"
    if (-not (Test-Path -Path $versionFilePath)) {
        Write-Host "No game version found! Creating new VERSION file at $versionFilePath..."
        New-Item -ItemType File -Path $versionFilePath | Out-Null
        Set-Content -Path $versionFilePath -Value "Nothing"
    }

    # Get the current version from the VERSION file
    $currentVersion = Get-Content -Path $versionFilePath

    # Get the latest version from the GitHub repository
    $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/$RepoOwner/$RepoName/releases/latest"
    $latestVersion = $releaseInfo.tag_name

    # Check if the latest version is different from the current version
    if ($currentVersion -ne $latestVersion) {
        Write-Host "Updating game version from $currentVersion to $latestVersion..."

        # Erase the contents of the game folder
        Get-ChildItem -Path $GameFolder -Recurse | Remove-Item -Force -Recurse

        # Get a list of artifacts for the latest release and find the game zip file
        $gameArtifact = $releaseInfo.assets | Where-Object { $_.name -like "*.zip" }
        if (-not $gameArtifact) {
            Write-Host "Error: Game artifact not found in the latest release."
            exit 1
        }

        # Download the game zip file
        $zipFileUrl = $gameArtifact.browser_download_url
        $zipFilePath = Join-Path -Path $GameFolder -ChildPath $gameArtifact.name
        Write-Host "Downloading $($gameArtifact.name) from $zipFileUrl..."
        Invoke-WebRequest -Uri $zipFileUrl -OutFile $zipFilePath
        if (-not (Test-Path -Path $zipFilePath)) {
            Write-Host "Error: Failed to download the game zip file."
            exit 1
        }

        # Extract the downloaded zip file
        Expand-Archive -Path $zipFilePath -DestinationPath $GameFolder -Force

        # Remove the downloaded zip file after extraction
        Remove-Item -Path $zipFilePath -Force

        # Update the VERSION file with the latest version
        Set-Content -Path $versionFilePath -Value $latestVersion

        Write-Host "Update complete. Current version is now $latestVersion."
    } else {
        Write-Host "Game is already up to date (version $currentVersion)."
    }
}

# Run for every game in metadata.pegasus.txt
$lines = Get-Content -Path 'metadata.pegasus.txt'
$repoOwner = $null
$repoName = $null
$gameFolder = $null

for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i].Trim()
    if ($line -like 'game:*') {
        # Reset parameters for each new game entry
        $repoOwner = $null
        $repoName = $null
        $gameFolder = $null

        # Look ahead for the required fields
        for ($j = $i + 1; $j -lt $lines.Count; $j++) {
            $nextLine = $lines[$j].Trim()
            if ($nextLine -like 'game:*') { break } # Next entry found

            if ($nextLine -like 'repo_owner:*') {
                $repoOwner = $nextLine -replace 'repo_owner:\s*', ''
            }
            elseif ($nextLine -like 'repo_name:*') {
                $repoName = $nextLine -replace 'repo_name:\s*', ''
            }
            elseif ($nextLine -like 'game_folder:*') {
                $gameFolder = $nextLine -replace 'game_folder:\s*', ''
            }

            if ($repoOwner -and $repoName -and $gameFolder) { break }
        }

        if ($repoOwner -and $repoName -and $gameFolder) {
            Write-Host "Updating game: $repoOwner/$repoName in folder $gameFolder"
            UpdateGame -RepoOwner $repoOwner -RepoName $repoName -GameFolder $gameFolder
        }
    }
}