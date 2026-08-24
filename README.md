# Terraform: Ubuntu VM + Minikube on OpenStack

Terraform configurations for provisioning an Ubuntu VM on an OpenStack cloud
and bootstrapping it into a 3-node Minikube Kubernetes cluster, including the
network setup required to reach the VM.

## 📁 Repository structure

```text
terraform/
├── modules/compute/   # reusable module: OpenStack compute instance
└── projects/
    ├── minikube/      # Ubuntu VM bootstrapped into a 3-node Minikube cluster
    └── docker/        # Ubuntu VM with Docker only (lighter alternative)
```

Each project reuses the `compute` module and ships its own provisioning
scripts (`scripts/base.sh`, `scripts/docker.sh`, `scripts/minikube.sh`)
executed on the VM after creation.

## 📄 Key files

| File | Purpose |
|---|---|
| `providers.tf` | OpenStack provider definition and parameters |
| `variables.tf` | input variable declarations |
| `locals.tf` | frequently used local values kept in one place |
| `main.tf` | resources to create |
| `terraform.auto.tfvars.example` | template for filling in variables (copy to `terraform.auto.tfvars`) |

## 🚀 Usage

Prerequisite: OpenStack credentials available as environment variables
(e.g. an *application credential* exported as `OS_*` variables).

```bash
cp terraform.auto.tfvars.example terraform.auto.tfvars   # then fill in values
terraform init     # initialize providers/modules
terraform plan     # review what will be created
terraform apply    # create the infrastructure
```

Once applied, verify by SSH-ing into the created Ubuntu VM using its assigned
IP address and your key pair (e.g. PuTTY or `ssh ubuntu@<vm-ip>`).
