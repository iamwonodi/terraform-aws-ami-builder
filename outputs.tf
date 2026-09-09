################################################################################
# IMAGE BUILDER COMPONENT
################################################################################

output "component_arn" {
  description = "ARN of the Image Builder component used to customize the parent image."
  value       = aws_imagebuilder_component.this.arn
}


################################################################################
# IMAGE RECIPE
################################################################################

output "recipe_arn" {
  description = "ARN of the Image Builder recipe used to create the AMI."
  value       = aws_imagebuilder_image_recipe.this.arn
}


################################################################################
# BUILD INFRASTRUCTURE
################################################################################

output "infrastructure_configuration_arn" {
  description = "ARN of the temporary Image Builder infrastructure configuration."
  value       = aws_imagebuilder_infrastructure_configuration.this.arn
}


################################################################################
# DISTRIBUTION CONFIGURATION
################################################################################

output "distribution_configuration_arn" {
  description = "ARN of the Image Builder distribution configuration."
  value       = aws_imagebuilder_distribution_configuration.this.arn
}


################################################################################
# BUILT AMI
################################################################################

output "ami_id" {
  description = "ID of the AMI produced by the immediate Image Builder build. Null when build_image is false."
  value = (
    var.build_image
    ? try(
      one(aws_imagebuilder_image.this[0].output_resources[0].amis[*].image),
      null
    )
    : null
  )
}

output "image_arn" {
  description = "ARN of the Image Builder image resource. Null when build_image is false."
  value = (
    var.build_image
    ? aws_imagebuilder_image.this[0].arn
    : null
  )
}


################################################################################
# IMAGE BUILDER PIPELINE
################################################################################

output "pipeline_arn" {
  description = "ARN of the Image Builder pipeline. Null when enable_pipeline is false."
  value = (
    var.enable_pipeline
    ? aws_imagebuilder_image_pipeline.this[0].arn
    : null
  )
}