################################################################################
# AMI BUILDER LOCALS
#
# Centralizes resource names and common tags so naming remains consistent
# across every AWS Image Builder resource created by this module.
################################################################################

locals {
  aws_region = data.aws_region.current.region

  component_name = (
    "${var.project_name}-${var.environment}-${var.image_name}-component"
  )

  recipe_name = (
    "${var.project_name}-${var.environment}-${var.image_name}-recipe"
  )

  infrastructure_configuration_name = (
    "${var.project_name}-${var.environment}-${var.image_name}-build"
  )

  distribution_configuration_name = (
    "${var.project_name}-${var.environment}-${var.image_name}-distribution"
  )

  pipeline_name = (
    "${var.project_name}-${var.environment}-${var.image_name}-pipeline"
  )

  ami_name = (
    "${var.project_name}-${var.environment}-${var.image_name}"
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

  # ExecuteBash runs its commands as one bash script, which does not stop at a
  # failed command: only the last one decides whether the step passes. A failed
  # install could therefore produce an image without the software, and a failed
  # check pass validation. Every script starts by stopping at the first failure.
  # (No -u: callers' scripts may rely on unset variables.)
  script_preamble = ["set -eo pipefail"]

  build_script      = concat(local.script_preamble, var.component_build_commands)
  validation_script = concat(local.script_preamble, local.validation_commands)

  common_tags = merge(
    var.tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}