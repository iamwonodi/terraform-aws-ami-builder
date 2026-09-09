
################################################################################
# CORE IDENTIFICATION
################################################################################

variable "project_name" {
  type        = string
  description = "Project name used to identify the Image Builder resources."
  default     = "example"

  validation {
    condition     = trimspace(var.project_name) != ""
    error_message = "project_name must not be empty."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment used to identify the Image Builder resources."
  default     = "development"

  validation {
    condition     = trimspace(var.environment) != ""
    error_message = "environment must not be empty."
  }
}


################################################################################
# BASE IMAGE
################################################################################

variable "parent_image" {
  type        = string
  description = "AMI ID or Image Builder parent-image ARN used as the starting point for the new AMI."

  validation {
    condition     = trimspace(var.parent_image) != ""
    error_message = "parent_image must not be empty."
  }
}


################################################################################
# VERSIONING
################################################################################

variable "component_version" {
  type        = string
  description = "Semantic version assigned to the Image Builder component."
  default     = "1.0.0"

  validation {
    condition = can(regex(
      "^[0-9]+\\.[0-9]+\\.[0-9]+$",
      var.component_version
    ))

    error_message = "component_version must use semantic versioning in the form X.Y.Z."
  }
}

variable "recipe_version" {
  type        = string
  description = "Semantic version assigned to the Image Builder recipe."
  default     = "1.0.0"

  validation {
    condition = can(regex(
      "^[0-9]+\\.[0-9]+\\.[0-9]+$",
      var.recipe_version
    ))

    error_message = "recipe_version must use semantic versioning in the form X.Y.Z."
  }
}


################################################################################
# STORAGE
################################################################################

variable "root_volume_size" {
  type        = number
  description = "Size in GiB of the encrypted root EBS volume included in the resulting AMI."
  default     = 24

  validation {
    condition     = var.root_volume_size >= 8
    error_message = "root_volume_size must be at least 8 GiB."
  }
}

variable "root_volume_type" {
  type        = string
  description = "EBS volume type used for the encrypted root volume."
  default     = "gp3"

  validation {
    condition = contains(
      ["gp3", "gp2"],
      lower(var.root_volume_type)
    )

    error_message = "root_volume_type must be either gp3 or gp2."
  }
}


################################################################################
# BUILD INFRASTRUCTURE
################################################################################

variable "instance_types" {
  type        = list(string)
  description = "EC2 instance types that Image Builder may use while constructing the AMI."
  default     = ["t3.medium"]
}

variable "instance_profile_name" {
  type        = string
  description = "IAM instance profile attached to the temporary EC2 build instance."

  validation {
    condition     = trimspace(var.instance_profile_name) != ""
    error_message = "instance_profile_name must not be empty."
  }
}

variable "subnet_id" {
  type        = string
  description = "Subnet where Image Builder launches the temporary EC2 build instance."

  validation {
    condition     = trimspace(var.subnet_id) != ""
    error_message = "subnet_id must not be empty."
  }
}

variable "security_group_ids" {
  type        = set(string)
  description = "Security groups attached to the temporary EC2 build instance."
}


################################################################################
# BUILD
################################################################################

variable "build_image" {
  type        = bool
  description = "When true, Terraform creates an Image Builder image resource and starts an immediate AMI build."
  default     = false
}

variable "build_trigger" {
  type        = string
  description = "Caller-controlled value used to explicitly request another AMI build. Change this value when a manual rebuild is required."
  default     = ""
}

variable "ami_description" {
  type        = string
  description = "Description assigned to the resulting AMI."
  default     = "Reusable compute AMI."
}


################################################################################
# PIPELINE
################################################################################

variable "enable_pipeline" {
  type        = bool
  description = "Whether to create the recurring Image Builder pipeline."
  default     = false
}

variable "pipeline_schedule" {
  type        = string
  description = "EventBridge cron or rate expression controlling when the Image Builder pipeline checks for an eligible build."
  default     = "cron(0 3 ? * SUN *)"
}

variable "enable_image_tests" {
  type        = bool
  description = "Whether Image Builder performs its built-in AMI tests."
  default     = true
}

variable "image_test_timeout_minutes" {
  type        = number
  description = "Maximum number of minutes allowed for Image Builder AMI tests."
  default     = 60
}

variable "key_pair" {
  description = "Optional EC2 key pair name for SSH access to the temporary build instance."
  type        = string
  default     = null
}

variable "logging_bucket_name" {
  description = "S3 bucket where Image Builder uploads build logs."
  type        = string
}

variable "sns_topic_arn" {
  description = "Optional SNS topic ARN for build event notifications."
  type        = string
  default     = null
}


################################################################################
# TAGGING
################################################################################

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to all Image Builder resources."
  default     = {}
}