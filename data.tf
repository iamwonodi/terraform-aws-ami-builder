################################################################################
# AWS REGION
#
# Reads the AWS region selected by the Terraform AWS provider.
#
# The region is used by the distribution configuration to register the
# resulting AMI in the same region where the module is being deployed.
################################################################################

data "aws_region" "current" {}