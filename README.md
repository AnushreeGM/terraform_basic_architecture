# 🏗️ Terraform AWS Custom VPC Setup

This project provisions a complete **Custom VPC environment in AWS** using Terraform, including:

- Custom VPC with public and private subnets
- Internet Gateway and NAT Gateway
- Route tables and associations
- Security Groups and Network ACLs
- EC2 instances in public and private subnets
- Web server installed on both instances using user data

---

## 📁 Project Structure

```bash
.
├── main.tf              # Contains the full Terraform configuration
├── .gitignore           # Ignores sensitive and unnecessary files
└── README.md            # Project documentation

🚀 Getting Started
### 🔧 **1. Clone the Repository**

```bash
git clone https://github.com/your-username/terraform_custom_vpc.git
cd terraform_custom_vpc
```

---
###  **2. Initialize Terraform**

```bash
terraform init
```
---
###  **3. Review the Execution Plan**

```bash
terraform plan
```

---
###  **4.  Apply and Create Resources**

```bash
terraform apply
```

---
###  Clean Up

```bash
terraform destroy
```

Important Notes
Region: All resources are created in eu-north-1. You can change this in the provider block.

AMI: Replace the AMI ID with a valid one for your region if needed (ami-0dd574ef87b79ac6c).

Credentials: Ensure your AWS credentials are configured via environment variables or AWS CLI.
