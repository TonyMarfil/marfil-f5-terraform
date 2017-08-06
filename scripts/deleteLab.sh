#!/bin/bash
emailid=$1

aws iam list-groups|jq .Groups[].GroupName|grep terraform-admin &> /dev/null
if [ $? != 0 ]
  then
  echo "You must be an admin to run this script"
  exit 1
fi


region=`aws configure get region`
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION-$region}

export TF_VAR_aws_region=${AWS_DEFAULT_REGION}
export TF_VAR_terraform_aws_vpc=terraform-vpc-${emailid}
export TF_VAR_aws_keypair=MyKeyPair-${emailid}
export TF_VAR_emailid=${emailid}
export TF_VAR_emailidsan=`echo ${emailid} | sed 's/[\@._-]//g'`
export TF_VAR_aws_alias='foobar'
export emailid=$1

touch ${TF_VAR_emailidsan}.crt
touch ${TF_VAR_emailidsan}.key

# delete local state
rm -rf .terraform

# initialize s3
terraform init -backend-config bucket=f5-public-cloud-${AWS_DEFAULT_REGION} -backend-config key=${TF_VAR_emailidsan}.terraform.tfstate -backend-config region=${AWS_DEFAULT_REGION}

# delete keys
scripts/lab-cleanup
terraform destroy -force

if [ $? != 0 ]
  then
  echo "Terraform destroy failed.  Please try again or manually clean-up lingering resources."
  exit 1
fi

# delete state bucket
scripts/deleteBucket.sh
scripts/deleteUser.sh $1

