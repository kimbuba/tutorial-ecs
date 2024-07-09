#!/bin/sh

export AWS_CLI_PROFILE=myapp-ecs-user
export CLUSTER_NAME=myapp-ecs-cluster
export SERVICE_NAME=myapp-ecs-service

#Force new deployment
aws --profile $AWS_CLI_PROFILE ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force-new-deployment
