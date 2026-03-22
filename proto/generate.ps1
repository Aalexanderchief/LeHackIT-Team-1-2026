param(
  [string]$Root = ".."
)

$ErrorActionPreference = "Stop"

$serverDir = Join-Path $PSScriptRoot "..\server"
$protoFile = Join-Path $PSScriptRoot "controller.proto"

Write-Host "[proto] Generating TypeScript artifacts..."
Set-Location $serverDir
npx pbjs -t static-module -w commonjs -o src/generated/controller.js $protoFile
npx pbts -o src/generated/controller.d.ts src/generated/controller.js

Write-Host "[proto] Generating Dart artifacts..."
Set-Location $PSScriptRoot
protoc --dart_out=..\mobile\lib\generated -I=. controller.proto

Write-Host "[proto] Done"
