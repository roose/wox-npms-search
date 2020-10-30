nim c -d:release --opt:size --passL:-s npms.nim

# get version from plugin.json
$version = (Get-Content plugin.json | ConvertFrom-Json).version

# delete npms-search.zip, npms-search.$version.wox
Remove-Item "npms-search.zip", "npms-search.$version.wox" -ErrorAction 0

$images = Join-Path $PSScriptRoot "Images"
$exe = Join-Path $PSScriptRoot "npms.exe"
$json = Join-Path $PSScriptRoot "plugin.json"

$compress = @{
  Path = $images, $exe, $json
  CompressionLevel = "Optimal"
  DestinationPath = $PSScriptRoot + "\npms-search.zip"
}
# compress files
Compress-Archive @compress

#rename .zip to .wox and add version
Rename-Item "npms-search.zip" "npms-search.$version.wox"
