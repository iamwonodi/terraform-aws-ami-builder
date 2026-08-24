################################################################################
# AWS EC2 IMAGE BUILDER
#
# This module creates reusable Amazon Machine Images (AMIs) using AWS EC2
# Image Builder.
#
# The module is operating-system and workload agnostic. The caller controls:
#
# - The parent AMI
# - Software installation commands
# - Optional validation commands
# - Build infrastructure
# - Root EBS configuration
# - AMI description
# - Optional immediate AMI build
# - Optional recurring Image Builder pipeline
#
# The module itself does not assume:
#
# - Ubuntu
# - Amazon Linux
# - Docker
# - AWS CLI
# - Any specific application
#
# The caller is responsible for deciding what software and operating-system
# configuration belongs in the resulting AMI.
################################################################################


################################################################################
# IMAGE BUILDER COMPONENT
#
# Creates the Image Builder component that defines the operating-system
# configuration and software installation performed during the AMI build.
#
# The build commands are supplied by the caller through
# var.component_build_commands.
#
# Validation commands are supplied through var.component_validate_commands.
# The validate phase is created only when validation commands are provided.
################################################################################

resource "aws_imagebuilder_component" "base" {
  name        = local.component_name
  platform    = "Linux"
  version     = var.component_version
  description = var.component_description

  data = yamlencode({
    name          = local.component_name
    description   = var.component_description
    schemaVersion = 1.0

    phases = [
      {
        name = "build"

        steps = [
          {
            name      = "InstallAndConfigureSoftware"
            action    = "ExecuteBash"
            onFailure = "Abort"

            inputs = {
              commands = var.component_build_commands
            }
          }
        ]
      },

      {
        name = "validate"

        steps = [
          {
            name      = "ValidateSoftwareInstallation"
            action    = "ExecuteBash"
            onFailure = "Abort"

            inputs = {
              commands = local.validation_commands
            }
          }
        ]
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = local.component_name
      Type = "AMI Builder Component"
    }
  )
}


################################################################################
# IMAGE RECIPE
#
# Defines the exact configuration used to construct the AMI.
#
# The recipe combines:
#
# - The caller-provided parent AMI
# - The Image Builder component created above
# - The root EBS volume configuration
#
# A new recipe version should be created when the caller intentionally changes
# the recipe configuration or wants to consume a different parent image.
################################################################################

resource "aws_imagebuilder_image_recipe" "base" {
  name         = local.recipe_name
  version      = var.recipe_version
  parent_image = var.parent_image

  working_directory = "/tmp"

  component {
    component_arn = aws_imagebuilder_component.base.arn
  }

  block_device_mapping {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.recipe_name
      Type = "AMI Recipe"
    }
  )
}


################################################################################
# IMAGE BUILDER INFRASTRUCTURE CONFIGURATION
#
# Defines the temporary EC2 build environment used by AWS Image Builder.
#
# AWS Image Builder launches a temporary EC2 instance using this configuration
# to execute the component commands and construct the AMI.
#
# The temporary build instance is separate from the final AMI. It is removed
# after the build process according to AWS Image Builder's lifecycle.
################################################################################

resource "aws_imagebuilder_infrastructure_configuration" "base" {
  name = local.infrastructure_configuration_name

  instance_types = var.instance_types

  instance_profile_name = var.instance_profile_name

  subnet_id                     = var.subnet_id
  security_group_ids            = var.security_group_ids
  terminate_instance_on_failure = true

  tags = merge(
    local.common_tags,
    {
      Name = local.infrastructure_configuration_name
      Type = "AMI Build Infrastructure"
    }
  )
}


################################################################################
# IMAGE BUILDER DISTRIBUTION CONFIGURATION
#
# Defines where AWS Image Builder registers the AMI after a successful build.
#
# This implementation registers the AMI in the AWS region selected by the
# Terraform AWS provider.
################################################################################

resource "aws_imagebuilder_distribution_configuration" "base" {
  name = local.distribution_configuration_name

  distribution {
    region = local.aws_region

    ami_distribution_configuration {
      name = "${local.ami_name}-{{ imagebuilder:buildDate }}"

      description = var.ami_description

      ami_tags = merge(
        local.common_tags,
        {
          Name       = local.ami_name
          Type       = "AMI"
          AMIVersion = var.recipe_version
        }
      )
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.distribution_configuration_name
      Type = "AMI Distribution"
    }
  )
}


################################################################################
# MANUAL BUILD TRIGGER
#
# terraform_data stores a caller-controlled value used to explicitly request
# another AMI build.
#
# Changing var.build_trigger causes terraform_data.build_trigger to change.
# The lifecycle configuration on aws_imagebuilder_image.base then forces that
# image resource to be replaced, causing AWS Image Builder to perform another
# AMI build.
#
# Example:
#
# build_trigger = "build-001"
#
# Later change to:
#
# build_trigger = "build-002"
#
# The changed value explicitly requests another build.
################################################################################

resource "terraform_data" "build_trigger" {
  input = var.build_trigger
}


################################################################################
# IMMEDIATE AMI BUILD
#
# When build_image is true, Terraform creates an AWS Image Builder image
# resource and AWS Image Builder performs an immediate AMI build.
#
# When build_image is false, the component, recipe, infrastructure
# configuration, and distribution configuration are still created, but no
# immediate AMI build is requested through this resource.
#
# The build_trigger lifecycle dependency allows the caller to request another
# build by changing var.build_trigger.
################################################################################

resource "aws_imagebuilder_image" "base" {
  count = var.build_image ? 1 : 0

  image_recipe_arn                 = aws_imagebuilder_image_recipe.base.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.base.arn
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.base.arn

  tags = merge(
    local.common_tags,
    {
      Name = local.ami_name
      Type = "AMI Build"
    }
  )

  lifecycle {
    replace_triggered_by = [
      terraform_data.build_trigger
    ]
  }
}


################################################################################
# OPTIONAL IMAGE BUILDER PIPELINE
#
# Creates an AWS Image Builder pipeline when var.enable_pipeline is true.
#
# The pipeline is a persistent AWS resource. It does not keep a build EC2
# instance running.
#
# At the configured schedule, Image Builder evaluates whether the pipeline has
# an eligible build. When the configured execution condition is satisfied,
# Image Builder launches the temporary build infrastructure and produces a new
# AMI.
#
# The pipeline is independent of the aws_imagebuilder_image resource above.
# Therefore, the caller can use either:
#
# - build_image for an immediate Terraform-managed build
# - the pipeline for recurring scheduled builds
################################################################################

resource "aws_imagebuilder_image_pipeline" "base" {
  count = var.enable_pipeline ? 1 : 0

  name = local.pipeline_name

  image_recipe_arn                 = aws_imagebuilder_image_recipe.base.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.base.arn
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.base.arn

  image_tests_configuration {
    image_tests_enabled = var.enable_image_tests
    timeout_minutes     = var.image_test_timeout_minutes
  }

  schedule {
    schedule_expression                = var.pipeline_schedule
    pipeline_execution_start_condition = "EXPRESSION_MATCH_AND_DEPENDENCY_UPDATES_AVAILABLE"
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.pipeline_name
      Type = "AMI Pipeline"
    }
  )
}