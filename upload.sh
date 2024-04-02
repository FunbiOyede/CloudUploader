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
    bucketPath=$(yq '.config.s3BucketPath' ${configFile})
    bucketName=$(yq '.config.s3BucketName' ${configFile})
    localFileName=$(yq '.config.fileName' ${configFile})
    region=$(yq '.config.region' ${configFile})
    expiresIn=$(yq '.config.expiresIn' ${configFile})

    if [ ${isMultipleFiles} == true ]; then
        echo "uploading folders...."
        UploadMultipleFilesToS3  ${localFilePath} ${bucketPath} ${bucketName} ${region} ${expiresIn} 
    else 
        echo "Uploading Single file...."
        UploadSingleFile ${localFilePath} ${localFileName} ${bucketPath} ${region} ${expiresIn} ${bucketName}
    fi
}

UploadMultipleFilesToS3() {

    local localFilePath=$1
    local bucketPath=$2
    local bucketName=$3
    local region=$4
    local expiresIn=$5


     if [ -z ${localFilePath} ] || [ -z ${bucketPath} ] || [ -z ${bucketName} ] || [ -z ${region} ] || [ -z ${expiresIn} ]; then
        echo "Error: Config fields required to upload multiple files is empty. Please populate values"
        exit 1
    else 
         echo "**** uploading to S3 bucket - ${bucketPath} ****"
         result=$(aws s3 sync ${localFilePath}  s3://${bucketPath} )
         statusCode=$?
    
        if [[ "$statusCode" -eq 0 ]]; then
            echo "${result}"
            echo " Multiple file uploaded Successfully 😊"
            echo "Generating Shareable links"

            bucketLists=$(aws s3api list-objects --bucket ${bucketName} | jq -r '.Contents.[].Key')
                for object in ${bucketLists}
                do
                generatedUrls=$(aws s3 presign s3://${bucketName}/${object} --expires-in ${expiresIn} --region ${region})
                urls=($generatedUrls)
                echo "${urls},"
                done
                echo "urls expires in ${expiresIn} Seconds"
            exit 0
        else
            echo "${result}"
            echo "Error: Multiple File upload not Successful...."
            exit 1
        fi
    fi
}



# checkFileExistInBucket() {

#     local fileName=$1
#     local bucketName=$2
#     local bucketPath=$3
#     local localFilePath=$4
#     local result=

#     ObjectList=$(aws s3api list-objects --bucket ${bucketName})
    
#     if [[ -n ${ObjectList} ]]; then

#         objectKey=$(aws s3api list-objects --bucket ${bucketName} | jq -r '.Contents.[].Key')

#         if [ "$objectKey" = *${fileName}* ]; then
#             echo "File already exist in the bucket, Reply o to overwite or s to skip" 
#             read os
#             if [[ $os == "r" ]]; then
#                 echo "Renaming...."
#                 # Delete file 
#                 aws s3 rm s3://${bucketPath}/${fileName}
#                 #Upload again 
#                 result=$(aws s3 cp ${localFilePath}  s3://${bucketPath})
#             elif [[ $os == "s" ]]; then
#                 echo "Skipping...."
#                 result=$(aws s3 cp ${localFilePath}  s3://${bucketPath})
#             else
#                 exit 1
#             fi
#         else
#             result=$(aws s3 cp ${localFilePath}  s3://${bucketPath})
#         fi

       
#     else
#         echo "S3 bucket is empty, creating new file"
#         result=$(aws s3 cp ${localFilePath}  s3://${bucketPath})
#     fi

# }


UploadSingleFile() {

    local localFilePath=$1
    local localFileName=$2
    local bucketPath=$3
    local region=$4
    local expiresIn=$5
    local bucketName=$6

    if [ -z ${localFilePath} ] || [ -z ${bucketPath} ]; then
        echo "Error: Config fields required to upload single file is empty. Please populate values"
        exit 1
    else 
        result=$(aws s3 cp ${localFilePath}  s3://${bucketPath})
        statusCode=$?
        if [[ "$statusCode" -eq 0 ]]; then
            echo "${result}"
            echo " file uploaded Successfully 😊"
            echo "Generating Shareable link...."

            generatedUrls=$(aws s3 presign s3://${bucketPath}${localFileName} --expires-in ${expiresIn} --region ${region})
            urls=($generatedUrls)
            echo ${urls}
            echo "urls expires in ${expiresIn} Seconds"
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

