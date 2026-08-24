################################################################################
# AMI BUILDER COMPLETE EXAMPLE
#
# This example demonstrates how a caller can use the generic ami-builder
# module to create an AMI from an existing parent AMI.
#
# The module does not decide which operating-system packages or applications
# are installed. The caller supplies those commands.
################################################################################

module "ami_builder" {
  source = "../.."

  project_name = var.project_name
  environment  = var.environment

  # The caller decides which parent AMI is used.
  parent_image = var.parent_image

  # The caller decides exactly what software/configuration is installed.
  component_build_commands = [
    "export DEBIAN_FRONTEND=noninteractive",
    "apt-get update -y",
    "apt-get install -y git jq unzip tar gzip curl wget nano ca-certificates gnupg lsb-release"
  ]

  # The caller decides what should be validated after installation.
  component_validate_commands = [
    "curl --version",
    "jq --version",
    "git --version",
    "nano --version"
  ]

  component_version = var.component_version
  recipe_version    = var.recipe_version

  root_volume_size = var.root_volume_size
  root_volume_type = var.root_volume_type

  instance_types        = var.instance_types
  instance_profile_name = var.instance_profile_name
  subnet_id             = var.subnet_id
  security_group_ids    = var.security_group_ids

  # Set true when an immediate build is required.
  build_image = var.build_image

  # Change this value to explicitly request another build.
  build_trigger = var.build_trigger

  ami_description = var.ami_description

  enable_pipeline            = var.enable_pipeline
  pipeline_schedule          = var.pipeline_schedule
  enable_image_tests         = var.enable_image_tests
  image_test_timeout_minutes = var.image_test_timeout_minutes

  tags = var.tags
}


