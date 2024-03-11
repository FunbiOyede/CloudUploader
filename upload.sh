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
        service=$(yq '.config.service' ${configFile})

         if [ -z ${service} ]; then
            echo "Service field is empty. Check config file"
            exit 1
        
        else 
            if [[ "${aws_storage_service[@]}" =~ "${service}" ]]; then
                echo "This tool supports upload to ${service}"
                upload $service
            else
                echo "This tool doesn't support upload operations for this AWS ${service}"
                exit 1
            fi
        fi
    fi
}


upload() {
   local service=$1
     
        if [[ $service == "s3" ]]; then
        echo "Uploading data to aws ${service} storage...."
            uploadToS3

        else
            echo "Cannot upload to any storage service at the moment";
            exit 1
        fi
}

uploadToS3() {

    file=$(yq '.config.filePath' ${configFile})
    bucket=$(yq '.config.bucketPath' ${configFile})
    isFolder=$(yq '.config.isFolder' ${configFile})
     
    if [ -z ${file} ] || [ -z ${bucket} || -z ${isFolder} ]; then
        echo "Config fields are empty. Please populate Values"
        exit 1
    else 
        echo "Bucket name is  - ${bucket}...."
        echo "**** uploading to S3 bucket - ${bucket} ****"
        if [ ${isFolder} == true ]; then
            echo "uploading folders...."
            result=$(aws s3 sync ${file}  s3://${bucket})
        else 
            echo "Uploading file...."
            result=$(aws s3 cp ${file}  s3://${bucket})
        fi
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
    fi

}


main() {

    isAuth

    isAccess

    processConfig

    upload

}


main

