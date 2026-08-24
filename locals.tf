################################################################################
# AMI BUILDER LOCALS
#
# Centralizes resource names and common tags so naming remains consistent
# across every AWS Image Builder resource created by this module.
################################################################################

locals {
  aws_region = data.aws_region.current.region

  component_name = (
    "${var.project_name}-${var.environment}-ami-component"
  )

  recipe_name = (
    "${var.project_name}-${var.environment}-ami-recipe"
  )

  infrastructure_configuration_name = (
    "${var.project_name}-${var.environment}-ami-build"
  )

  distribution_configuration_name = (
    "${var.project_name}-${var.environment}-ami-distribution"
  )

  pipeline_name = (
    "${var.project_name}-${var.environment}-ami-pipeline"
  )

  ami_name = (
    "${var.project_name}-${var.environment}-ami"
  )

  # Image Builder requires commands in the validation step.
  #
  # When the caller does not provide validation commands, the module performs
  # a harmless validation command instead of creating an empty command list.
  validation_commands = (
    length(var.component_validate_commands) > 0
    ? var.component_validate_commands
    : ["echo 'No custom validation commands configured.'"]
  )

  common_tags = merge(
    var.tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}