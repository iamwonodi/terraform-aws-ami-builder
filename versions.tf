terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # >= 6.0.0 comfortably covers every feature this module uses, including
      # infrastructure_configuration's placement block -- confirmed merged
      # into the provider around April 2025 (PR #42381), which predates the
      # 6.x provider line. key_pair, logging, resource_tags, and
      # sns_topic_arn on infrastructure_configuration are all long-established
      # and not a version-floor concern.
      version = ">= 6.0.0, < 7.0.0"
    }
  }
}
