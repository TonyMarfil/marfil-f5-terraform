#!/bin/bash
if [ $F5_ENV == "development" ]
  then
  aws s3 rm  s3://f5-public-cloud-development-terraform-${AWS_DEFAULT_REGION}/${TF_VAR_emailidsan}.terraform.tfstate
  else
  aws s3 rm  s3://f5-public-cloud-terraform-${AWS_DEFAULT_REGION}/${TF_VAR_emailidsan}.terraform.tfstate
fi


