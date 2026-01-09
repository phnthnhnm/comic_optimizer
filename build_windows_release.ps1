# Clean old build files
flutter clean

# Build release with obfuscation and split debug info
flutter build windows --release --obfuscate --split-debug-info=build/debug-info

# Get latest git tag for versioning
$tag = git describe --tags --abbrev=0
$cleanTag = $tag -replace "^v", ""
$zipName = "comic_optimizer-$cleanTag-windows-x64.zip"

# Compress the build output using 7z at max compression
$releaseFolder = "build/windows/x64/runner/Release"
if (Test-Path $releaseFolder) {
    $zipPath = Join-Path $releaseFolder $zipName
    if (Test-Path $zipPath) { Remove-Item $zipPath }
    Push-Location $releaseFolder
    # Find UPX (must be available in PATH)
    $upxCmd = (Get-Command upx -ErrorAction SilentlyContinue).Source

    if ($upxCmd) {
        Write-Host "Compressing executables with UPX: $upxCmd"
        $patterns = @('*.exe','*.dll')
        Get-ChildItem -Recurse -Include $patterns -File | ForEach-Object {
            try {
                & $upxCmd --best --lzma $_.FullName
            } catch {
                Write-Warning "UPX failed on $($_.FullName): $_"
            }
        }
    } else {
        Write-Host "UPX not found in PATH. To enable executable compression, install UPX (e.g. 'choco install upx' or 'scoop install upx')."
    }

    7z a -tzip -mx=9 $zipName *
    Pop-Location
    Invoke-Item $releaseFolder
} else {
    Write-Host "Build output folder not found."
}
