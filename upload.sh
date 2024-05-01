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


############################## Upload to S3 #######################################################

uploadToS3() {


    isMultipleFiles=$(yq '.config.isMultipleFiles' ${configFile})
    localFilePath=$(yq '.config.localFilePath' ${configFile})
    bucket=$(yq '.config.bucket' ${configFile})
    localFileName=$(yq '.config.fileName' ${configFile})

    if [ ${isMultipleFiles} == true ]; then
        echo "uploading folders...."
        UploadMultipleFilesToS3  ${localFilePath} ${bucket} 
    else 
        echo "Uploading Single file...."
        UploadSingleFile ${localFilePath} ${localFileName} ${bucket}
    fi
}




UploadMultipleFilesToS3() {

    local localFilePath=$1
    local bucket=$2

     if [ -z ${localFilePath} ] || [ -z ${bucket} ]; then
        echo "Error: Config fields required to upload multiple files is empty. Please populate values"
        exit 1
    else 
         echo "**** uploading to S3 bucket - ${bucket} ****"
         result=$(aws s3 sync ${localFilePath}  s3://${bucket} )
         echo "${result}"
         statusCode=$?
    
        if [[ "$statusCode" -eq 0 ]]; then
            echo " Multiple file uploaded Successfully 😊"
            exit 0
        else
            echo "${result}"
            echo "Error: Multiple File upload not Successful...."
            exit 1
        fi
    fi
}



UploadSingleFile() {

    local localFilePath=$1
    local localFileName=$2
    local bucket=$3

    if [ -z ${localFilePath} ] || [ -z ${bucket} ]; then
        echo "Error: Config fields required to upload single file is empty. Please populate values"
        exit 1
    else 
        result=$(aws s3 cp ${localFilePath}  s3://${bucket})
        statusCode=$?
        if [[ "$statusCode" -eq 0 ]]; then
            echo "${result}"
            echo " file uploaded Successfully 😊"
            exit 0
        else
            echo "${result}"
            echo "Error: Single File upload not Successful...."
            exit 1
        fi
    fi
}



############################## Upload to DynaMoDB #######################################################

main() {

    isAuth

    isAccess

    processConfig

    upload

}


main

