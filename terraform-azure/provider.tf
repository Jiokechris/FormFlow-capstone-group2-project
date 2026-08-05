# ---------------------------------------------------------------------------
# WHAT IS THIS FILE?
# Terraform needs to know two things before it can do ANYTHING:
#   1. Which "provider" (cloud) am I talking to?  -> Azure, here.
#   2. What version of that provider's plugin should I use?
# This file answers both. Think of it as "which delivery company are we
# using, and which version of their app."
# ---------------------------------------------------------------------------

terraform {
  # Pin the Terraform CLI version so "it works on my machine" problems
  # don't happen later when the tool itself changes behavior.
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm" # the official Azure plugin for Terraform
      version = "~> 3.90"           # "3.90 or a newer patch/minor of 3.x, not 4.x"
    }
  }
}

# The "provider" block actually configures the plugin above.
# features {} is required by azurerm even when empty — Azure uses it for
# provider-wide behavior toggles we don't need to touch right now.
provider "azurerm" {
  features {}
}
