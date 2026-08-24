# AWS AMI Builder Terraform Module

A generic Terraform module for building reusable Amazon Machine Images (AMIs) with **AWS EC2 Image Builder**.

This module is intentionally operating-system and workload agnostic. It does not install a predefined set of packages. Instead, the caller supplies the shell commands that should be executed during the image build and validation phases.

This allows the same module to build:

* Ubuntu AMIs
* Amazon Linux AMIs
* Debian-based AMIs
* Other Linux distributions supported by AWS EC2 Image Builder

The operating system and software configuration are controlled by the caller.

---

## Architecture

```text
                         Terraform Caller
                                |
                                |
                                v
                    +-----------------------+
                    |     ami-builder       |
                    |       module          |
                    +-----------+-----------+
                                |
                +---------------+---------------+
                |               |               |
                v               v               v
        +---------------+ +-------------+ +-------------+
        |   Component   | |   Recipe    | |    Build    |
        |               | |             | |Infrastructure|
        | Build Commands| | Parent AMI  | | Subnet      |
        | Validation    | | Component   | | SGs         |
        | Commands      | | Root EBS    | | IAM Profile |
        +-------+-------+ +------+------+ | EC2 Type    |
                |                |        +------+------+
                +----------------+---------------+
                                 |
                                 v
                    +-----------------------+
                    |   Image Builder      |
                    |       Build          |
                    +-----------+-----------+
                                |
                                v
                       +----------------+
                       |   Distribution |
                       | Configuration  |
                       +--------+-------+
                                |
                                v
                         +-------------+
                         |     AMI     |
                         +-------------+

                    Optional recurring pipeline
                                |
                                v
                     +----------------------+
                     | Image Builder        |
                     | Pipeline             |
                     |                     |
                     | Schedule             |
                     | Image Tests          |
                     +----------+-----------+
                                |
                                v
                     New AMI versions when
                     execution is eligible
```

---

## What This Module Creates

The module can create the following AWS EC2 Image Builder resources:

| Resource                                        | Purpose                                                                    |
| ----------------------------------------------- | -------------------------------------------------------------------------- |
| `aws_imagebuilder_component`                    | Defines the commands executed during the image build and validation phases |
| `aws_imagebuilder_image_recipe`                 | Combines the parent image, component, and root EBS configuration           |
| `aws_imagebuilder_infrastructure_configuration` | Defines the temporary EC2 environment used during the AMI build            |
| `aws_imagebuilder_distribution_configuration`   | Defines where and how the resulting AMI is registered                      |
| `aws_imagebuilder_image`                        | Performs an immediate AMI build when enabled                               |
| `aws_imagebuilder_image_pipeline`               | Optionally creates a recurring Image Builder pipeline                      |
| `terraform_data.build_trigger`                  | Provides a caller-controlled mechanism for manually triggering a new build |

---

# Module Design

The module separates responsibilities between the caller and the module.

## Caller Responsibilities

The caller decides:

* Which parent AMI is used
* Which software is installed
* How software is configured
* Which validation commands are executed
* Which EC2 instance type Image Builder uses
* Which subnet is used for the build
* Which security groups are attached
* Which IAM instance profile is used
* Root EBS volume size and type
* Whether an immediate build should occur
* Whether a recurring pipeline should exist
* Pipeline schedule
* Image testing configuration
* Tags

## Module Responsibilities

The module creates and connects:

```text
Component
    |
    v
Recipe
    |
    +---- Parent Image
    |
    +---- Root EBS configuration
    |
    v
Infrastructure Configuration
    |
    +---- Temporary build instance
    |
    +---- Subnet
    |
    +---- Security Groups
    |
    +---- IAM Instance Profile
    |
    v
Distribution Configuration
    |
    v
AMI
```

---

# Why the Module Is Generic

The module does not contain commands such as:

```text
apt-get install docker
dnf install docker
yum install docker
```

Instead, the caller provides commands:

```hcl
component_build_commands = [
  "apt-get update -y",
  "apt-get install -y docker.io",
  "systemctl enable docker",
  "systemctl start docker"
]
```

Therefore, an Ubuntu caller can provide Ubuntu commands while an Amazon Linux caller can provide Amazon Linux commands.

The module itself does not need to change.

---

# Example Directory Structure

```text
ami-builder/
├── main.tf
├── variables.tf
├── locals.tf
├── data.tf
├── outputs.tf
├── versions.tf
├── .gitignore
├── README.md
└── examples/
    └── complete/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

# Required Provider

The module uses the HashiCorp AWS provider.

The module should be consumed with a compatible AWS provider version defined in `versions.tf`.

The current HashiCorp AWS provider documentation confirms support for the Image Builder resources used by this module.

---

# Input Variables

## Project Identification

### `project_name`

Name used to identify the Image Builder resources.

Example:

```hcl
project_name = "blueprints"
```

### `environment`

Environment used to distinguish resources.

Example:

```hcl
environment = "development"
```

---

# Component Configuration

## `component_description`

Description assigned to the Image Builder component.

Example:

```hcl
component_description = "Ubuntu compute base software configuration."
```

---

## `component_build_commands`

Shell commands executed during the Image Builder build phase.

Example:

```hcl
component_build_commands = [
  "apt-get update -y",
  "apt-get install -y git jq curl wget nano",
  "systemctl enable docker",
  "systemctl start docker"
]
```

These commands are executed inside the temporary Image Builder build instance.

The resulting filesystem becomes part of the AMI.

---

## `component_validate_commands`

Optional commands used to verify that the build completed successfully.

Example:

```hcl
component_validate_commands = [
  "git --version",
  "jq --version",
  "curl --version"
]
```

If no validation commands are required:

```hcl
component_validate_commands = []
```

---

# Parent Image

## `parent_image`

Defines the starting image for the build.

AWS Image Builder image recipes accept an AMI ID, Image Builder image ARN, or an SSM parameter reference as the parent image.

Example using an AMI:

```hcl
parent_image = "ami-0123456789abcdef0"
```

Example using an Image Builder parent image:

```hcl
parent_image = "arn:aws:imagebuilder:..."
```

Example using an SSM parameter:

```hcl
parent_image = "ssm:/aws/service/..."
```

The exact parent image must be compatible with the commands supplied through `component_build_commands`.

---

# Versioning

## `component_version`

Semantic version of the Image Builder component.

Example:

```hcl
component_version = "1.0.0"
```

When the component definition changes, increment the component version.

Recommended approach:

```text
1.0.0
 |
 | Minor functional improvement
 v
1.1.0
 |
 | Bug fix
 v
1.1.1
```

---

## `recipe_version`

Semantic version of the Image Builder recipe.

Example:

```hcl
recipe_version = "1.0.0"
```

Increment this when the recipe itself changes, such as changing the parent image or root volume configuration.

---

# Root EBS Configuration

## `root_volume_size`

Size of the root EBS volume in GiB.

Example:

```hcl
root_volume_size = 24
```

---

## `root_volume_type`

Root EBS volume type.

Example:

```hcl
root_volume_type = "gp3"
```

The module currently supports:

```text
gp3
gp2
```

---

# Build Infrastructure

Image Builder launches a temporary EC2 instance to perform the build.

The instance is not the final AMI.

It exists only to construct and test the image.

---

## `instance_types`

EC2 instance types Image Builder can use during the build.

Example:

```hcl
instance_types = [
  "t3.medium"
]
```

---

## `instance_profile_name`

IAM instance profile attached to the temporary Image Builder build instance.

Example:

```hcl
instance_profile_name = "ami-builder-instance-profile"
```

The profile may be necessary when the build commands need AWS API access.

Examples include:

* Downloading private artifacts from S3
* Reading SSM parameters
* Accessing AWS APIs
* Retrieving private resources
* Performing AWS-specific configuration during the build

If the build commands do not require AWS API access, the profile can be minimal and should follow least-privilege principles.

---

## `subnet_id`

Subnet where Image Builder launches the temporary build instance.

Example:

```hcl
subnet_id = "subnet-0123456789abcdef0"
```

The subnet must provide the network connectivity required by the build commands.

For example, if the build needs to download packages from the internet, the subnet must have an appropriate egress path.

---

## `security_group_ids`

Security groups attached to the temporary Image Builder build instance.

Example:

```hcl
security_group_ids = [
  "sg-0123456789abcdef0"
]
```

The security group must permit whatever outbound connectivity is required by the build.

---

# Immediate AMI Build

## `build_image`

Controls whether Terraform creates an immediate Image Builder image build.

Example:

```hcl
build_image = true
```

When:

```hcl
build_image = false
```

Terraform creates the Image Builder configuration but does not start an immediate AMI build.

When:

```hcl
build_image = true
```

Terraform creates the Image Builder image resource and AWS Image Builder starts the build.

---

# Manual Build Trigger

## `build_trigger`

Provides a caller-controlled mechanism for requesting another build.

Example:

```hcl
build_trigger = "build-001"
```

To request another build:

```hcl
build_trigger = "build-002"
```

The value itself has no AWS meaning.

It exists to give Terraform a deliberate change that can trigger replacement of the `aws_imagebuilder_image` resource.

The module implements this using:

```hcl
resource "terraform_data" "build_trigger" {
  input = var.build_trigger
}
```

and:

```hcl
lifecycle {
  replace_triggered_by = [
    terraform_data.build_trigger
  ]
}
```

Therefore changing:

```text
build-001
```

to:

```text
build-002
```

causes Terraform to replace the Image Builder image resource and initiate another AMI build.

---

# Image Distribution

## `ami_description`

Description assigned to the resulting AMI.

Example:

```hcl
ami_description = "Reusable Ubuntu compute AMI."
```

---

# Image Builder Pipeline

## `enable_pipeline`

Controls whether the recurring Image Builder pipeline is created.

Example:

```hcl
enable_pipeline = true
```

When disabled:

```hcl
enable_pipeline = false
```

no recurring Image Builder pipeline is created.

---

## `pipeline_schedule`

Defines when Image Builder evaluates the pipeline for execution.

Example:

```hcl
pipeline_schedule = "cron(0 3 ? * SUN *)"
```

This represents:

```text
Every Sunday
at 03:00 UTC
```

The pipeline does not mean that Terraform runs every Sunday.

The pipeline exists in AWS and AWS Image Builder manages its scheduled executions.

---

# Pipeline Execution Condition

The module uses:

```hcl
pipeline_execution_start_condition = "EXPRESSION_MATCH_AND_DEPENDENCY_UPDATES_AVAILABLE"
```

This means the scheduled execution must satisfy both the configured schedule and the dependency-update condition before Image Builder proceeds.

The pipeline is separate from the temporary EC2 build instance. Image Builder creates the build environment when a pipeline execution actually occurs.

---

# Image Testing

## `enable_image_tests`

Controls whether Image Builder performs its built-in image tests.

Recommended:

```hcl
enable_image_tests = true
```

---

## `image_test_timeout_minutes`

Maximum amount of time allocated to the Image Builder image tests.

Example:

```hcl
image_test_timeout_minutes = 60
```

---

# Tags

## `tags`

Additional tags supplied by the caller.

Example:

```hcl
tags = {
  Owner       = "platform"
  CostCenter  = "engineering"
  Application = "compute"
}
```

The module also applies its own common tags.

---

# Example: Ubuntu AMI

A caller can use this generic module to create an Ubuntu AMI by supplying Ubuntu-specific commands.

```hcl
module "ubuntu_ami" {
  source = "git::https://github.com/iamwonodi/terraform-aws-ami-builder.git?ref=v1.0.0"

  project_name = "blueprints"
  environment  = "development"

  parent_image = "ami-xxxxxxxxxxxxxxxxx"

  component_description = "Ubuntu compute base AMI."

  component_build_commands = [
    "export DEBIAN_FRONTEND=noninteractive",
    "apt-get update -y",
    "apt-get upgrade -y",
    "apt-get install -y git jq curl wget nano ca-certificates",

    "install -m 0755 -d /etc/apt/keyrings",
    "curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc",
    "chmod a+r /etc/apt/keyrings/docker.asc",

    "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $$(. /etc/os-release && echo $${UBUNTU_CODENAME:-$$VERSION_CODENAME}) stable\" > /etc/apt/sources.list.d/docker.list",

    "apt-get update -y",
    "apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",

    "systemctl enable docker",
    "systemctl start docker",
    "usermod -aG docker ubuntu"
  ]

  component_validate_commands = [
    "git --version",
    "jq --version",
    "docker --version",
    "docker compose version",
    "aws --version"
  ]

  component_version = "1.0.0"
  recipe_version    = "1.0.0"

  root_volume_size = 24
  root_volume_type = "gp3"

  instance_types = [
    "t3.medium"
  ]

  instance_profile_name = "ami-builder-instance-profile"

  subnet_id = "subnet-xxxxxxxxxxxxxxxxx"

  security_group_ids = [
    "sg-xxxxxxxxxxxxxxxxx"
  ]

  build_image = true

  build_trigger = "build-001"

  enable_pipeline = false

  ami_description = "Ubuntu compute AMI for platform workloads."

  tags = {
    Project     = "blueprints"
    Environment = "development"
    ManagedBy   = "Terraform"
  }
}
```

---

# Example: Manual Rebuild

Assume the current configuration contains:

```hcl
build_trigger = "build-001"
```

To explicitly request another build:

```hcl
build_trigger = "build-002"
```

Then run:

```text
terraform plan
terraform apply
```

Terraform detects the change to `terraform_data.build_trigger` and replaces the Image Builder image resource.

---

# Example: Scheduled Pipeline

A caller that wants recurring builds can configure:

```hcl
enable_pipeline = true

pipeline_schedule = "cron(0 3 ? * SUN *)"

enable_image_tests = true

image_test_timeout_minutes = 60
```

The pipeline remains managed by AWS Image Builder.

Terraform creates the pipeline configuration; AWS Image Builder handles scheduled executions.

---

# Versioning Strategy

Use semantic versioning.

## Component Changes

When changing:

```hcl
component_build_commands
```

increment:

```hcl
component_version
```

Example:

```text
1.0.0 → 1.1.0
```

for a meaningful new capability.

---

## Recipe Changes

Increment:

```hcl
recipe_version
```

when changing recipe-level configuration such as:

* Parent image
* Root EBS configuration
* Recipe configuration

Example:

```text
1.0.0 → 1.0.1
```

---

## Build Trigger

Use `build_trigger` when an explicit build is required without relying on the pipeline schedule.

Example:

```text
build-001
build-002
build-003
```

Keep the trigger value unique for each intentional manual build.

---

# Important Operational Principle

The module does not automatically decide what software belongs in the AMI.

The caller owns that decision.

For example:

```text
ami-builder
    |
    +-- Ubuntu + Docker
    |
    +-- Ubuntu + Docker + AWS CLI
    |
    +-- Ubuntu + Docker + monitoring agent
    |
    +-- Amazon Linux + Docker
    |
    +-- Debian + application runtime
```

All of these can use the same Terraform module.

Only the caller-supplied commands change.

---

# Security Considerations

Do not place secrets directly inside:

```hcl
component_build_commands
```

Do not hard-code:

* Passwords
* API keys
* Access keys
* Private tokens
* Database credentials
* Long-lived AWS credentials

Golden AMIs should contain software and configuration that is safe to distribute to the intended compute fleet.

Runtime secrets should be retrieved at runtime through an appropriate secrets mechanism.

---

# Network Requirements

The temporary Image Builder instance must be able to reach whatever resources are required by the supplied build commands.

Depending on the parent image and commands, this may require access to:

* Ubuntu package repositories
* Docker package repositories
* AWS endpoints
* S3
* Systems Manager
* ECR
* Other private repositories

For private or isolated build subnets, the required VPC endpoints and routing must be provided by the caller.

---

# Outputs

The module exposes the resources required by the caller, including:

```text
component_arn
recipe_arn
infrastructure_configuration_arn
distribution_configuration_arn
ami_id
image_arn
pipeline_arn
```

When an optional resource is disabled, its corresponding output is `null`.

For example, when:

```hcl
build_image = false
```

the AMI output is:

```text
null
```

---

# Terraform Workflow

From the module directory:

```powershell
terraform fmt -recursive
terraform init
terraform validate
terraform plan
terraform apply
```

After making configuration changes:

```powershell
terraform fmt -recursive
terraform validate
terraform plan
```

Apply only after reviewing the plan:

```powershell
terraform apply
```

---

# Destroying the Module

To remove the Image Builder infrastructure managed by Terraform:

```powershell
terraform destroy
```

Review the destruction plan carefully before confirming.

The resulting AMIs may have lifecycle implications outside the Terraform resources that created them, so production AMI retention should be considered before destroying Image Builder configuration.

---

# Module Repository

Recommended repository name:

```text
terraform-aws-ami-builder
```

Recommended module directory:

```text
modules/ami-builder
```

Example module reference:

```hcl
module "ami_builder" {
  source = "git::https://github.com/iamwonodi/terraform-aws-ami-builder.git?ref=v1.0.0"
}
```

---

# Summary

This module provides a reusable Terraform abstraction around AWS EC2 Image Builder.

The architecture is:

```text
Caller
  |
  +--> Parent Image
  |
  +--> Build Commands
  |
  +--> Validation Commands
  |
  +--> Build Infrastructure
  |
  +--> Storage Configuration
  |
  +--> Pipeline Configuration
  |
  v
AMI Builder Module
  |
  +--> Component
  +--> Recipe
  +--> Infrastructure Configuration
  +--> Distribution Configuration
  +--> Optional Image Build
  +--> Optional Pipeline
  |
  v
Reusable AMI
```

The key design principle is that **the module provides the Image Builder machinery while the caller provides the operating-system and software decisions**.
