param(
  [string]$InstanceId,
  [string]$Region = "us-east-1",
  [int]$LocalPort = 6443,
  [int]$RemotePort = 6443
)

$ErrorActionPreference = "Stop"

if (-not $InstanceId) {
  $InstanceId = terraform -chdir=terraform output -raw instance_id
}

$pluginPath = "C:\Program Files\Amazon\SessionManagerPlugin\bin"
if (Test-Path $pluginPath) {
  $env:PATH = "$pluginPath;$env:PATH"
}

aws ssm start-session `
  --region $Region `
  --target $InstanceId `
  --document-name AWS-StartPortForwardingSession `
  --parameters "portNumber=$RemotePort,localPortNumber=$LocalPort"

