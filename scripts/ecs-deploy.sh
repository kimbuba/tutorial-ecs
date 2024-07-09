#!/bin/sh

export PROJECT_ROOT=/PATH/TO/ecs-tutorial
export ECR_URL=YOUR_URL.dkr.ecr.us-east-1.amazonaws.com
export AWS_CLI_PROFILE=myapp-ecs-user
export TAG_NAME=myapp
export MYAPP_VERSION=1.0
export AWS_REGION=us-east-1
export PLATFORM=linux/arm64/v8
export TASK_DEFINITION_NAME=myapp-ec2-task
export CLUSTER_NAME=myapp-ecs-cluster
export SERVICE_NAME=myapp-ecs-service
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

#
## 3. Create a new task definition revision
echo "---- Creating new task definition"
# by default, this gets the latest ACTIVE revision, which is usually what you want.
EXISTING_TASKDEF="$(aws --profile $AWS_CLI_PROFILE ecs describe-task-definition --task-definition=$TASK_DEFINITION_NAME)"  || exit
EXISTING_TASKDEF_ARN="$(jq -r '.taskDefinition.taskDefinitionArn' <<< "$EXISTING_TASKDEF")"  || exit
echo "-Creating new task definition from $EXISTING_TASKDEF_ARN"
# create new taskdef using jq to replace the image key in the first container (we assume only one container `.containerDefinitions[0]` is defined in this example)
# describe-task-definition returns some keys that can't be used with register-task-definition, so we delete those, too
NEW_TASK_DEFINITION="$(jq --arg IMAGE "$ECR_IMAGE" '.taskDefinition | .containerDefinitions[0].image = $IMAGE | del(.taskDefinitionArn) | del(.revision) | del(.status) | del(.requiresAttributes) | del(.compatibilities) | del(.registeredAt) | del(.registeredBy)' <<< "$EXISTING_TASKDEF")"  || exit
# register the new revision
NEW_REVISION_ARN="$(aws --profile $AWS_CLI_PROFILE ecs register-task-definition --cli-input-json "$NEW_TASK_DEFINITION" --output text --query 'taskDefinition.taskDefinitionArn')"  || exit
echo "-Created new task definition to $NEW_REVISION_ARN"
# 3. Update the service to use the new revision
aws --profile $AWS_CLI_PROFILE ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --task-definition="$NEW_REVISION_ARN"  > new-task-def.txt
echo "-Update service $SERVICE_NAME"
