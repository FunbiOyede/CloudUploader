#!/bin/bash
set -e

configFile=$1

echo "Welcome to my simple cloud upload tool 😊, I hope you finding it very useful. 😁 Gracias!!!"

 
aws_storage_service=("aurora" "dynamodb" "rds" "s3")

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



processConfig() {

    if [[ -z ${configFile} ]]; then
        echo "Config file not found"
        exit 1
    else
        bucketName=$(yq '.config.bucketName' ${configFile})
        filePath=$(yq '.config.filePath' ${configFile})
        fileName=$(yq '.config.fileName' ${configFile})
        service=$(yq '.config.service' ${configFile})
        bucketPath=$(yq '.config.bucketPath' ${configFile})
        
        if [ -z ${service} ] || [ -z ${filePath} ]  || [ -z ${fileName} ] || [ -z ${bucketName} ] || [ -z ${bucketPath} ] ; then
            echo "Config fields are empty. Please populate Values"
            exit 1
        else 
        
            # echo ""
            upload $service $bucketPath $filePath
        fi

    fi
}


upload() {
   local service=$1
   local bucket=$2
   local file=$3

     if [[ "${aws_storage_service[@]}" =~ "${service}" ]]; then
        echo "This tool supports upload to ${service}"
             
        if [[ "$1" == "s3" ]]; then
        echo "Uploading data to aws ${service} storage...."
            uploadToS3 $bucket $file

        else
            echo "Cannot upload to any storage service at the moment";
            exit 1
        fi

    else
        echo "This tool doesn't support upload operations for this AWS ${service}"
        exit 1
    fi
}

uploadToS3() {
    local bucket=$1
    local file=$2
        echo "Bucket name is  - ${bucket}...."
        echo "**** uploading to S3 bucket - ${bucket} ****"

        # versionId=$(aws s3api put-object --bucket ${bucketName} --key ${fileName}  --body ${filePath} | jq '.VersionId')
        result=$(aws s3 cp ${file}  s3://${bucket})
        statusCode=$?
    
        if [[ "$statusCode" == 0 ]]; then
            echo "${result}"
            echo " File uploaded Successfully 😊"
            exit 0
        else
            echo "${result}"
            echo "File upload not Successful...."
            exit 1
        fi

}


main() {

    isAuth

    isAccess

    processConfig

    upload

}


main

