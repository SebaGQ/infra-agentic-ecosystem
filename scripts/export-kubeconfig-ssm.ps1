param(
  [string]$InstanceId,
  [string]$Region = "us-east-1",
  [string]$OutputPath = ".\kubeconfig-ssm.yaml"
)

$ErrorActionPreference = "Stop"

if (-not $InstanceId) {
  $InstanceId = terraform -chdir=terraform output -raw instance_id
}

$commandId = aws ssm send-command `
  --region $Region `
  --instance-ids $InstanceId `
  --document-name AWS-RunShellScript `
  --comment "Read k3s kubeconfig for local SSM tunnel" `
  --parameters commands="sudo cat /etc/rancher/k3s/k3s.yaml" `
  --query "Command.CommandId" `
  --output text

aws ssm wait command-executed `
  --region $Region `
  --command-id $commandId `
  --instance-id $InstanceId

$result = aws ssm get-command-invocation `
  --region $Region `
  --command-id $commandId `
  --instance-id $InstanceId `
  --output json | ConvertFrom-Json

if ($result.ResponseCode -ne 0) {
  throw $result.StandardErrorContent
}

$config = $result.StandardOutputContent `
  -replace 'https://127\.0\.0\.1:6443', 'https://127.0.0.1:6443' `
  -replace 'https://[^:]+:6443', 'https://127.0.0.1:6443'

Set-Content -LiteralPath $OutputPath -Value $config -Encoding utf8
Write-Output "Wrote $OutputPath"

