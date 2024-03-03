#!/bin/bash
set -e
storage_service=$1

echo "Welcome to my simple cloud upload tool 😊, I hope you finding it very useful. 😁 Gracias!!!"

isAuth() {

    echo "Checking if user is authenticated...."

    USER_ID=$(aws sts get-caller-identity | jq '.UserId')

    if [[ -n "$USER_ID" ]]; then
        echo "User Id is set...."

    else
        echo "User Id not set...😔"
        exit 1
    fi
}

isAccess() {
    echo "Checking Access...."

    AccessKey=$(aws iam list-access-keys | jq '.AccessKeyMetadata[].AccessKeyId')
    UserName=$(aws iam list-access-keys | jq '.AccessKeyMetadata[].UserName')
    status=$(aws iam list-access-keys | jq '.AccessKeyMetadata[].Status')

    if [ -n "${AccessKey}" ] || [ -n "${UserName}" ]; then
        echo "User ${UserName} is ${status}...."

    else
        echo "AccessKeyId not found....😔"
        exit 1

    fi
}

aws_storage_service=("aurora" "dynamodb" "rds" "s3")

checkStorageService() {

    if [[ "${aws_storage_service[@]}" =~ "$storage_service" ]]; then
        echo "This tool supports upload to ${storage_service}"
    else
        echo "This tool doesn't support upload operations for this AWS ${storage_service}"
        exit 1
    fi
}

uploadToS3() {

    echo "Uploading data to aws ${storage_service} storage...."

    S3_Buckets=$(aws s3 ls)

    echo "Current S3 buckets ${S3_Buckets}"
}

isAuth

isAccess

checkStorageService

uploadToS3
