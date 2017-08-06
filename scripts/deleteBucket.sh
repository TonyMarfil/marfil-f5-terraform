#!/bin/bash
aws s3 rm  s3://f5-public-cloud-terraform-${AWS_DEFAULT_REGION}/${TF_VAR_emailidsan}.terraform.tfstate
