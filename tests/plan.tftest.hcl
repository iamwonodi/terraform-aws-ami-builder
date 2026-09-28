# Plans the module against a mocked AWS provider. Run with "terraform test"
# (or "tofu test") from the repository root.

mock_provider "aws" {
  mock_resource "aws_imagebuilder_component" {
    defaults = {
      arn = "arn:aws:imagebuilder:af-south-1:123456789012:component/example/1.0.0/1"
    }
  }
  mock_resource "aws_imagebuilder_image_recipe" {
    defaults = {
      arn = "arn:aws:imagebuilder:af-south-1:123456789012:image-recipe/example/1.0.0"
    }
  }
  mock_resource "aws_imagebuilder_infrastructure_configuration" {
    defaults = {
      arn = "arn:aws:imagebuilder:af-south-1:123456789012:infrastructure-configuration/example"
    }
  }
  mock_resource "aws_imagebuilder_distribution_configuration" {
    defaults = {
      arn = "arn:aws:imagebuilder:af-south-1:123456789012:distribution-configuration/example"
    }
  }
}

variables {
  parent_image             = "arn:aws:imagebuilder:af-south-1:aws:image/ubuntu-server-24-lts-x86/x.x.x"
  instance_profile_name    = "example-profile"
  subnet_id                = "subnet-0123456789abcdef0"
  security_group_ids       = ["sg-0123456789abcdef0"]
  component_build_commands = ["apt-get update -y", "apt-get install -y jq"]
}

run "scripts_stop_at_the_first_failure" {
  command = plan

  # ExecuteBash does not stop at a failed command on its own: a failed install
  # used to leave the image without the software and still pass.
  assert {
    condition     = yamldecode(aws_imagebuilder_component.this.data).phases[0].steps[0].inputs.commands == ["set -eo pipefail", "apt-get update -y", "apt-get install -y jq"]
    error_message = "The build script should start with set -eo pipefail, then the caller's commands in order."
  }

  assert {
    condition     = yamldecode(aws_imagebuilder_component.this.data).phases[1].steps[0].inputs.commands[0] == "set -eo pipefail"
    error_message = "The validation script should start with set -eo pipefail."
  }
}

run "root_device_defaults_to_xvda" {
  command = plan

  assert {
    condition     = one(aws_imagebuilder_image_recipe.this.block_device_mapping).device_name == "/dev/xvda"
    error_message = "Without root_device_name the recipe keeps v2.0.0's /dev/xvda."
  }
}

run "root_device_for_ubuntu" {
  command = plan

  variables {
    root_device_name = "/dev/sda1"
  }

  assert {
    condition     = one(aws_imagebuilder_image_recipe.this.block_device_mapping).device_name == "/dev/sda1"
    error_message = "root_device_name should reach the recipe's block device mapping."
  }
}

run "root_device_must_be_a_device_path" {
  command = plan

  variables {
    root_device_name = "sda1"
  }

  expect_failures = [var.root_device_name]
}
