#!/bin/bash

ok=0

while [ $ok = 0 ]
do
  if [ -z "$emailid" ]; then
    echo "Enter an email address - 25 characters max:
    "
    read emailid
  fi

  if [ -f "./aws_accesskeys_${emailid}.json" ]; then 
    echo "Account exists. Exporting shell variables.
    "
    . ./scripts/export.sh
    ok=1
  elif [ ${#emailid} -gt 25 ]; then
    echo Too long - 25 characters max
  else
    ok=1

alias=f5agility2017
emailidsan=`echo $emailid | sed 's/[\@._-]//g'`
groupName=terraform-lab-user

# create user

aws iam create-user \
--path "/" \
--user-name "$emailid"

# add user to admins group

aws iam add-user-to-group --user-name $emailid --group-name $groupName

# create access key

aws iam create-access-key --user-name "$emailid" | tee aws_accesskeys_$emailid.json

# create console login

aws iam create-login-profile \
--user-name "$emailid" \
  --password $shortUrl

# create account alias
#
# aws iam create-account-alias \
# --account-alias "$alias"

# get user info

aws iam get-user \
--user-name "$emailid"

# get user policies

aws iam list-user-policies \
--user-name "$emailid"

# create ssh keys and store private key locally

aws ec2 create-key-pair --key-name MyKeyPair-${emailid} --query 'KeyMaterial' --output text > MyKeyPair-${emailid}.pem
chmod 400 MyKeyPair-${emailid}.pem

#just in case...
aws iam delete-server-certificate --server-certificate-name elb_cert_${emailid} 2> /dev/null

#create a self-signed SSL certificate
openssl req -subj '/O=test LTD./CN=f5.io/C=US' -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout ${emailidsan}.key -out ${emailidsan}.crt -nodes

# replace temporary aws config file with new account aws access key and secret access key; uses envsubst from the gettext package.

region=`aws configure get region`
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION-$region}

# sleep 5s
sleep 5s

# touch *.emailid file.
touch $emailid.emailid

# export environment variables for use by terraform

. ./scripts/export.sh

envsubst < ./scripts/config.template > ~/.aws/config

if [ $F5_ENV == "development" ]
  then
  terraform init -backend-config bucket=f5-public-cloud-development-terraform-${AWS_DEFAULT_REGION} -backend-config key=${TF_VAR_emailidsan}.terraform.tfstate -backend-config region=${AWS_DEFAULT_REGION}
  else
  terraform init -backend-config bucket=f5-public-cloud-terraform-${AWS_DEFAULT_REGION} -backend-config key=${TF_VAR_emailidsan}.terraform.tfstate -backend-config region=${AWS_DEFAULT_REGION}
fi



fi
done
