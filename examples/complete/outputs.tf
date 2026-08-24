################################################################################
# OUTPUTS
################################################################################

output "ami_id" {
  description = "AMI ID produced by the Image Builder module."
  value       = module.ami_builder.ami_id
}

output "component_arn" {
  description = "ARN of the Image Builder component."
  value       = module.ami_builder.component_arn
}

output "recipe_arn" {
  description = "ARN of the Image Builder recipe."
  value       = module.ami_builder.recipe_arn
}

output "pipeline_arn" {
  description = "ARN of the Image Builder pipeline."
  value       = module.ami_builder.pipeline_arn
}