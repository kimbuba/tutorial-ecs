#!/bin/sh

export PROJECT_ROOT=/PATH/TO/ecs-tutorial
export ECR_URL=YOUR_URL.dkr.ecr.us-east-1.amazonaws.com
export AWS_CLI_PROFILE=myapp-ecs-user
export TAG_NAME=myapp
export MYAPP_VERSION=1.0
export AWS_REGION=us-east-1
export PLATFORM=linux/arm64/v8
export ECR_IMAGE=$ECR_URL/$TAG_NAME:$MYAPP_VERSION


# 1. Build image
cd $PROJECT_ROOT/scripts || exit
cd $PROJECT_ROOT/docker/server || exit
mkdir build-source
cp -R $PROJECT_ROOT/server/cmd $PROJECT_ROOT/server/go.mod build-source  || exit
docker build --build-arg APP_ENV=$APP_ENV --platform=$PLATFORM -t $TAG_NAME:$MYAPP_VERSION -f Dockerfile .  || exit
echo "---- Built image for $TAG_NAME:$MYAPP_VERSION"
#
## 2. Push image to ecr
aws --profile $AWS_CLI_PROFILE ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URL  || exit
docker tag $TAG_NAME:$MYAPP_VERSION $ECR_IMAGE  || exit
docker push $ECR_IMAGE  || exit
rm -rf $PROJECT_ROOT/docker/server/build-source/*  || exit
echo "---- Pushed image to ecr $ECR_IMAGE"
