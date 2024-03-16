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
    generateLink=$(yq '.config.generateLink' ${configFile})
    region=$(yq '.config.region' ${configFile})
    buckeName=$(yq '.config.bucketName' ${configFile})
    local isMultipleFiles= 
     
    if [ -z ${file} ] || [ -z ${bucket} || -z ${isFolder} ]; then
        echo "Config fields are empty. Please populate Values"
        exit 1
    else 
        echo "Bucket name is  - ${bucket}...."
        echo "**** uploading to S3 bucket - ${bucket} ****"
        if [ ${isFolder} == true ]; then
            isMultipleFiles=true
            echo "uploading folders...."
            result=$(aws s3 sync ${file}  s3://${bucket} )
        else 
            isMultipleFiles=false
            echo "Uploading file...."
            result=$(aws s3 cp ${file}  s3://${bucket})
        fi
        statusCode=$?
    
        if [[ "$statusCode" == 0 ]]; then
            echo "${result}"
            echo " File uploaded Successfully 😊"
            GeneratesShareLink $region $generateLink $isMultipleFiles $buckeName
            exit 0
        else
            echo "${result}"
            echo "File upload not Successful...."
            GeneratesShareLink $region $generateLink $isMultipleFiles $buckeName
            exit 1
        fi
    fi

}


GeneratesShareLink() {
   bucketRegion=$1
   isGenerateLink=$2
   isMultipleFiles=$3
   bucketName=$4

   if [[ ${isGenerateLink} == true ]]; then
        if [[ ${isMultipleFiles} == true ]]; then
            bucketLists=$(aws s3api list-objects --bucket ${bucketName} | jq -r '.Contents.[].Key')
            for object in ${bucketLists}
            do
               generatedUrls=$(aws s3 presign s3://${bucketName}/${object} --expires-in 604800 --region ${bucketRegion})
               urls=($generatedUrls)
               echo ${urls}
            done
             echo "urls expires in a week"
        else 
            echo "I Love Jesus"
        fi
   else 
        echo "why? no link?"
        # continue;
   fi
}

main() {

    isAuth

    isAccess

    processConfig

    upload

}


main

