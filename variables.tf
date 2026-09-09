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

variable "image_name" {
  type        = string
  description = "Distinguishing name segment used in every Image Builder resource this module creates. Lets more than one ami-builder instance -- called directly, or through a wrapper module -- coexist within the same project_name/environment without colliding on AWS resource names."
  default     = "ami"

  validation {
    condition     = trimspace(var.image_name) != ""
    error_message = "image_name must not be empty."
  }
}


################################################################################
# IMAGE COMPONENT
################################################################################

variable "component_description" {
  type        = string
  description = "Description assigned to the Image Builder component."
  default     = "Reusable compute AMI software and operating-system configuration."

  validation {
    condition     = trimspace(var.component_description) != ""
    error_message = "component_description must not be empty."
  }
}

variable "component_build_commands" {
  type        = list(string)
  description = "Shell commands executed during the Image Builder build phase to install and configure software in the AMI."

  validation {
    condition = (
      length(var.component_build_commands) > 0
      &&
      alltrue([
        for command in var.component_build_commands :
        trimspace(command) != ""
      ])
    )

    error_message = "component_build_commands must contain at least one non-empty command."
  }
}

variable "component_validate_commands" {
  type        = list(string)
  description = "Shell commands executed during Image Builder validation to verify that the software and configuration were installed successfully."

  default = []

  validation {
    condition = alltrue([
      for command in var.component_validate_commands :
      trimspace(command) != ""
    ])

    error_message = "component_validate_commands must contain only non-empty commands."
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

  validation {
    condition = (
      length(var.instance_types) > 0
      &&
      alltrue([
        for instance_type in var.instance_types :
        trimspace(instance_type) != ""
      ])
    )

    error_message = "instance_types must contain at least one non-empty EC2 instance type."
  }
}

variable "instance_profile_name" {
  type        = string
  description = "IAM instance profile attached to the temporary EC2 build instance launched by Image Builder."

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

  validation {
    condition = (
      length(var.security_group_ids) > 0
      &&
      alltrue([
        for security_group_id in var.security_group_ids :
        trimspace(security_group_id) != ""
      ])
    )

    error_message = "security_group_ids must contain at least one non-empty security group ID."
  }
}

variable "key_pair" {
  type        = string
  description = "Optional EC2 key pair name for SSH access to the temporary build instance, useful for debugging a failed build."
  default     = null
}

variable "logging_s3_bucket_name" {
  type        = string
  description = "Optional S3 bucket where Image Builder uploads build logs. Required together with logging_s3_key_prefix to enable build logging."
  default     = null
}

variable "logging_s3_key_prefix" {
  type        = string
  description = "S3 key prefix under which build logs are stored, when logging_s3_bucket_name is set."
  default     = null
}

variable "resource_tags" {
  type        = map(string)
  description = "Tags Image Builder applies to resources it creates during the build itself (the temporary EC2 instance, snapshots) -- distinct from tags, which apply to the Image Builder resources this module manages."
  default     = {}
}

variable "sns_topic_arn" {
  type        = string
  description = "Optional SNS topic ARN Image Builder publishes build and pipeline events to."
  default     = null
}

variable "placement_tenancy" {
  type        = string
  description = "Optional tenancy for the temporary build instance."
  default     = null

  validation {
    condition     = var.placement_tenancy == null || contains(["default", "dedicated", "host"], var.placement_tenancy)
    error_message = "placement_tenancy must be default, dedicated, or host."
  }
}

variable "placement_availability_zone" {
  type        = string
  description = "Optional Availability Zone for the temporary build instance."
  default     = null
}

variable "enhanced_image_metadata_enabled" {
  type        = bool
  description = "Whether Image Builder collects additional metadata about the image being created."
  default     = true
}


################################################################################
# AMI BUILD
################################################################################

variable "build_image" {
  type        = bool
  description = "When true, Terraform creates an Image Builder image resource and starts an AMI build."
  default     = false
}

variable "build_trigger" {
  type        = string
  description = "Caller-controlled value used to explicitly request another AMI build. Change this value when a manual rebuild is required."

  default = ""
}

variable "ami_description" {
  type        = string
  description = "Description assigned to the AMI produced by Image Builder."
  default     = "Reusable compute AMI."

  validation {
    condition     = trimspace(var.ami_description) != ""
    error_message = "ami_description must not be empty."
  }
}


################################################################################
# IMAGE BUILDER PIPELINE
################################################################################

variable "enable_pipeline" {
  type        = bool
  description = "Whether to create the recurring Image Builder pipeline."
  default     = false
}

variable "pipeline_schedule" {
  type        = string
  description = "EventBridge cron or rate expression that determines when the Image Builder pipeline checks for an eligible build."
  default     = "cron(0 3 ? * SUN *)"

  validation {
    condition     = trimspace(var.pipeline_schedule) != ""
    error_message = "pipeline_schedule must not be empty."
  }
}

variable "enable_image_tests" {
  type        = bool
  description = "Whether Image Builder runs its built-in tests against the AMI after the image build."
  default     = true
}

variable "image_test_timeout_minutes" {
  type        = number
  description = "Maximum number of minutes allowed for Image Builder AMI tests."
  default     = 60

  validation {
    condition     = var.image_test_timeout_minutes >= 1
    error_message = "image_test_timeout_minutes must be at least 1 minute."
  }
}


################################################################################
# TAGGING
################################################################################

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to all Image Builder resources."
  default     = {}
}