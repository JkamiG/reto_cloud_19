# Reto 19: Infraestructura Multi-Entorn amb AWS

Implementació d'una arquitectura Terraform multi-entorn per a AWS, amb VPCs separades per a `dev`, `staging` i `prod`, VPC Peering bidireccional entre dev i staging, instàncies EC2 (o ASG per a prod), i backend remot a S3 + DynamoDB.

---

## Arquitectura

```
┌─────────────────────────────────────────────────────────────────────┐
│                        AWS Account                                   │
│                                                                      │
│  ┌──────────────────┐   VPC Peering   ┌──────────────────────────┐  │
│  │   DEV VPC        │◄───────────────►│   STAGING VPC            │  │
│  │  10.0.0.0/16     │                 │  10.1.0.0/16             │  │
│  │                  │                 │                          │  │
│  │ ┌──────────────┐ │                 │ ┌──────────────────────┐ │  │
│  │ │ Public Subs  │ │                 │ │ Public Subnets       │ │  │
│  │ │ 10.0.1/2.0/24│ │                 │ │ 10.1.1/2.0/24        │ │  │
│  │ │   [IGW]      │ │                 │ │   [IGW] + [NAT GW]   │ │  │
│  │ └──────────────┘ │                 │ └──────────────────────┘ │  │
│  │ ┌──────────────┐ │                 │ ┌──────────────────────┐ │  │
│  │ │ Private Subs │ │                 │ │ Private Subnets      │ │  │
│  │ │ 10.0.3/4.0/24│ │                 │ │ 10.1.3/4.0/24        │ │  │
│  │ │  [EC2 t3.m]  │ │                 │ │  [EC2 t3.small]      │ │  │
│  │ └──────────────┘ │                 │ └──────────────────────┘ │  │
│  └──────────────────┘                 └──────────────────────────┘  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │   PROD VPC  10.2.0.0/16   (aïllat — sense peering amb dev)    │  │
│  │                                                                 │  │
│  │  Public Subnets: 10.2.1/2.0/24  [IGW] + [NAT GW]              │  │
│  │  Private Subnets: 10.2.3/4.0/24                                │  │
│  │  [ASG: t3.large, min=2, max=6, desired=2]                      │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │   S3 Bucket: reto19-terraform-state-<ACCOUNT_ID>               │  │
│  │   ├── dev/terraform.tfstate                                    │  │
│  │   ├── staging/terraform.tfstate                                │  │
│  │   └── prod/terraform.tfstate                                   │  │
│  │   DynamoDB Table: reto19-terraform-locks                       │  │
│  └────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Estructura del repositori

```
reto_cloud_19/
├── README.md
├── .gitignore
├── bootstrap/
│   └── state-backend.tf       # Crea S3 bucket + DynamoDB per al state
├── modules/
│   ├── networking/
│   │   ├── main.tf            # VPC, subnets, IGW, NAT, route tables
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── peering/
│   │   ├── main.tf            # VPC Peering bidireccional
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── compute/
│       ├── main.tf            # EC2 / Launch Template + ASG + SG
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    ├── dev/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── terraform.tfvars   # t3.micro, NAT=false, no ASG
    │   ├── backend.tf
    │   └── outputs.tf
    ├── staging/
    │   ├── main.tf            # Inclou peering amb dev via remote_state
    │   ├── variables.tf
    │   ├── terraform.tfvars   # t3.small, NAT=true, no ASG
    │   ├── backend.tf
    │   └── outputs.tf
    └── prod/
        ├── main.tf            # ASG habilitat, lifecycle prevent_destroy
        ├── variables.tf
        ├── terraform.tfvars   # t3.large, NAT=true, ASG min=2 max=6
        ├── backend.tf
        └── outputs.tf
```

---

## Prerequisits

- [AWS CLI](https://aws.amazon.com/cli/) ≥ 2.x configurat (`aws configure`)
- [Terraform](https://www.terraform.io/downloads) ≥ 1.6
- Credencials AWS amb permisos per crear VPC, EC2, S3, DynamoDB, IAM (mínim)
- L'`ACCOUNT_ID` de l'AWS account — obtenir amb: `aws sts get-caller-identity --query Account --output text`

---

## Configuració inicial: substitució de l'ACCOUNT_ID

Abans de desplegar, substituir `ACCOUNT_ID` pel valor real als fitxers backend:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Substituir als fitxers de backend
sed -i "s/ACCOUNT_ID/${ACCOUNT_ID}/g" \
  environments/dev/backend.tf \
  environments/staging/backend.tf \
  environments/prod/backend.tf \
  environments/staging/variables.tf
```

---

## Ordre de desplegament

### Pas 0: Bootstrap — Crear el backend S3 + DynamoDB

Aquest pas s'executa **una sola vegada** i crea la infraestructura de state remot.

```bash
cd bootstrap/
terraform init
terraform plan
terraform apply
```

> **Nota:** El bootstrap no té backend remot; usa l'estat local. Guardar `terraform.tfstate` del bootstrap de manera segura.

### Pas 1: Entorn DEV

```bash
cd environments/dev/
terraform init
terraform plan
terraform apply
```

### Pas 2: Entorn STAGING

El staging llegeix els outputs de dev via `terraform_remote_state`. Cal que dev estigui desplegat primer.

```bash
cd environments/staging/
terraform init
terraform plan
terraform apply
```

### Pas 3: Entorn PROD

```bash
cd environments/prod/
terraform init
terraform plan
terraform apply
```

---

## Procés de promoció de canvis (dev → staging → prod)

### Escenari: canviar `instance_type` de `t3.micro` a `t3.small` i afegir regla al port 8080

#### Fase DEV

```bash
# 1. Modificar environments/dev/terraform.tfvars
#    instance_type = "t3.small"

# 2. Afegir la nova regla a environments/dev/main.tf (dins ingress_rules):
#    { port = 8080, protocol = "tcp", cidr_blocks = ["10.0.0.0/8"], description = "App port" }

# 3. Plan i revisió
cd environments/dev
terraform plan -out=dev.tfplan

# 4. Revisar el pla (esperat: ~update in-place el SG, ~replace la instància EC2)
terraform show dev.tfplan

# 5. Aplicar
terraform apply dev.tfplan

# 6. Validació funcional a dev
```

#### Fase STAGING

```bash
# Repetir els mateixos canvis a environments/staging/terraform.tfvars i main.tf
cd environments/staging
terraform plan -out=staging.tfplan
# Revisar! Comparar amb dev.tfplan
terraform apply staging.tfplan
# Executar smoke tests / integration tests
```

#### Fase PROD (amb precaucions extra)

```bash
cd environments/prod
# Revisar el pla abans d'aplicar — OBLIGATORI en prod
terraform plan -out=prod.tfplan

# Revisió manual del pla (four-eyes principle)
terraform show prod.tfplan | grep -E "(replace|destroy)"

# Si hi ha recursos marcats com "must be replaced" → planificar finestra de manteniment
terraform apply prod.tfplan
```

---

## Destrucció segura per entorn

> ⚠️ **ATENCIÓ**: `prod` té `lifecycle { prevent_destroy = true }` al mòdul de networking. Cal eliminar-lo manualment abans de destruir.

```bash
# Destruir dev (no té protecció)
cd environments/dev
terraform destroy

# Destruir staging
cd environments/staging
terraform destroy

# Destruir prod (requereix eliminar prevent_destroy primer)
cd environments/prod
terraform destroy

# Destruir el bootstrap (última cosa a eliminar)
cd bootstrap
terraform destroy
```

---

## Decisions de disseny

### Directoris separats vs. Workspaces

S'han triat **directoris separats** (`environments/dev/`, `environments/staging/`, `environments/prod/`) en lloc de Terraform Workspaces perquè:

- Cada entorn té el seu propi fitxer d'estat independent a S3, eliminant el risc de destruir prod per error.
- Els fitxers `terraform.tfvars` i `backend.tf` poden ser completament independents per entorn.
- Facilita la revisió de canvis per entorn en PRs de Git.
- Permet dimensionaments radicalment diferents sense condicionals complexos al codi base.

### Peering dev ↔ staging (sense prod)

- Prod està aïllat per seguretat: no té peering amb dev ni staging.
- El staging llegeix l'estat de dev via `terraform_remote_state` per obtenir els IDs de VPC i route tables per al peering.

### NAT Gateway a dev desactivat

- `enable_nat_gateway = false` a dev per estalviar costos (~$32/mes per NAT GW).
- Les instàncies privades de dev no necessiten accés a internet per a les proves bàsiques.