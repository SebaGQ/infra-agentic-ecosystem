# Mini k3s GitOps en AWS

Base barata para ejecutar un cluster single-node de k3s en EC2 y operarlo con GitOps mediante FluxCD. La instancia no abre puertos inbound; la administración se hace con AWS Systems Manager Session Manager. El objetivo inicial es desplegar agentes autonomos usando `openclaw` como aplicacion base.

## Decisiones técnicas

- EC2 Ubuntu 22.04 con k3s single-node.
- Subnet pública con public IP solo para salida a internet. El Security Group no tiene reglas inbound.
- Egress HTTPS 443 hacia internet para SSM, descarga de k3s, GitHub y registries.
- Egress DNS TCP/UDP 53 solo hacia el CIDR de la VPC para resolver endpoints mediante AmazonProvidedDNS.
- k3s usa pod CIDR `10.244.0.0/16` y service CIDR `10.245.0.0/16` para no solaparse con la VPC `10.42.0.0/16`.
- Sin SSH, sin Ingress público, sin LoadBalancer público.
- Traefik deshabilitado; se conserva local-path provisioner y metrics-server por defecto de k3s.
- FluxCD se bootstrappea contra GitHub y reconcilia `clusters/dev`.
- No se guardan secretos reales en Git. Para una fase posterior usar SOPS + Age o AWS SSM Parameter Store.

## Arbol de archivos

```text
.
├── README.md
├── apps
│   └── openclaw
│       ├── base
│       │   ├── configmap.yaml
│       │   ├── deployment.yaml
│       │   ├── kustomization.yaml
│       │   ├── namespace.yaml
│       │   └── secret.example.yaml
│       └── overlays
│           └── dev
│               └── kustomization.yaml
├── clusters
│   └── dev
│       ├── kustomization.yaml
│       ├── namespaces
│       │   ├── kustomization.yaml
│       │   └── openclaw.yaml
│       └── openclaw.yaml
├── infra
│   └── base
│       └── kustomization.yaml
└── terraform
    ├── main.tf
    ├── outputs.tf
    ├── providers.tf
    ├── user_data.sh
    ├── variables.tf
    └── versions.tf
```

Nota: `apps/openclaw/base/namespace.yaml` queda como manifest base de referencia, pero el namespace se aplica desde `clusters/dev/namespaces` para evitar que dos Kustomizations de Flux administren el mismo objeto.

## Prerrequisitos locales

- Terraform instalado.
- AWS CLI v2 instalado y autenticado.
- Permisos AWS para VPC, EC2, IAM, SSM y EBS.
- Un repositorio GitHub donde ejecutar el bootstrap de Flux.
- Flux CLI. Puede instalarse localmente o dentro de la instancia por SSM.

Verifica credenciales:

```powershell
aws sts get-caller-identity
```

## Crear infraestructura

Desde la carpeta `terraform`:

```powershell
cd C:\Users\admin\Desktop\Infra_Agents_Codex\terraform
terraform init
terraform plan
terraform apply
```

Variables utiles:

```powershell
terraform plan -var="aws_region=us-east-1" -var="instance_type=t3.small"
```

## Validar recursos en AWS

Obtén los IDs:

```powershell
$INSTANCE_ID = terraform output -raw instance_id
$SG_ID = terraform output -raw security_group_id
```

Valida estado de la instancia:

```powershell
aws ec2 describe-instances `
  --instance-ids $INSTANCE_ID `
  --query "Reservations[0].Instances[0].{State:State.Name,PrivateIp:PrivateIpAddress,PublicIp:PublicIpAddress,IamProfile:IamInstanceProfile.Arn}" `
  --output table
```

Confirma que no hay inbound:

```powershell
aws ec2 describe-security-groups `
  --group-ids $SG_ID `
  --query "SecurityGroups[0].IpPermissions"
```

El resultado esperado es:

```json
[]
```

Confirma egress HTTPS:

```powershell
aws ec2 describe-security-groups `
  --group-ids $SG_ID `
  --query "SecurityGroups[0].IpPermissionsEgress"
```

Valida registro en SSM:

```powershell
aws ssm describe-instance-information `
  --filters "Key=InstanceIds,Values=$INSTANCE_ID" `
  --output table
```

Si la instancia aun no aparece, espera uno o dos minutos. `cloud-init`, k3s y el agente SSM pueden tardar después del primer boot.

## Conectar por SSM

```powershell
aws ssm start-session --target $INSTANCE_ID
```

No se crea key pair y no hay SSH.

## Validar k3s dentro de la instancia

Dentro de la sesión SSM:

```bash
cloud-init status --wait
sudo systemctl status k3s --no-pager
sudo k3s kubectl get nodes -o wide
sudo k3s kubectl get pods -A
```

El kubeconfig queda en:

```bash
/etc/rancher/k3s/k3s.yaml
```

Si quieres usar herramientas como `flux` sin sudo, prepara kubeconfig para el usuario de la sesión:

```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown "$USER:$USER" ~/.kube/config
chmod 600 ~/.kube/config
```

## Instalar Flux CLI dentro de la instancia

```bash
curl -s https://fluxcd.io/install.sh | sudo bash
flux --version
flux check --pre
```

## Bootstrap de Flux con GitHub

Ejecuta esto dentro de la instancia por SSM, usando un token de GitHub con permisos sobre el repositorio:

```bash
export GITHUB_TOKEN="<TOKEN_TEMPORAL>"

flux bootstrap github \
  --owner=<GITHUB_OWNER> \
  --repository=<REPO_NAME> \
  --branch=main \
  --path=./clusters/dev \
  --personal
```

No guardes el token en Git ni en archivos persistentes.

## Validar reconciliacion

```bash
flux get sources git
flux get kustomizations
sudo k3s kubectl get namespace openclaw
sudo k3s kubectl get deploy -n openclaw
sudo k3s kubectl get configmap -n openclaw
```

El Deployment usa la imagen:

```text
openclaw/openclaw:latest
```

## Secretos

`apps/openclaw/base/secret.example.yaml` es solo un ejemplo. No contiene valores reales y no se aplica automáticamente.

Para secretos reales, usar en una fase posterior:

- SOPS + Age con Flux.
- AWS SSM Parameter Store o AWS Secrets Manager con External Secrets Operator.

## Limpieza

Para destruir el ambiente:

```powershell
cd C:\Users\admin\Desktop\Infra_Agents_Codex\terraform
terraform destroy
```
