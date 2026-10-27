pipeline {
    agent any

    environment {
        REGISTRY           = '743978812281.dkr.ecr.eu-west-2.amazonaws.com'
        REPOSITORY         = 'shipit/orders-api'
        AWS_DEFAULT_REGION = 'eu-west-2'
        CLUSTER            = 'shipit-dev-cluster'
        SERVICE            = 'orders-api'
    }

    stages {
        stage('Build and test') {
            steps {
                dir('app') {
                    sh 'mvn -B verify'
                }
            }
        }

        stage('Build Docker image') {
            steps {
                script {
                    def sha = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    env.IMAGE_TAG = "${sha}-${env.BUILD_NUMBER}"
                }
                dir('app') {
                    sh 'docker build --platform linux/amd64 --provenance=false --sbom=false -t $REGISTRY/$REPOSITORY:$IMAGE_TAG .'
                }
            }
        }

        stage('Push to ECR') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aws-jenkins-ecr',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    sh '''
                        aws ecr get-login-password | docker login --username AWS --password-stdin $REGISTRY
                        docker push $REGISTRY/$REPOSITORY:$IMAGE_TAG
                    '''
                }
            }
        }

        stage('Approve deploy') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input message: "Deploy ${env.IMAGE_TAG} to dev?", ok: 'Deploy'
                }
            }
        }

        stage('Deploy to ECS') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aws-jenkins-ecr',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    sh '''
                        set -e
                        CURRENT=$(aws ecs describe-services --cluster $CLUSTER --services $SERVICE \
                            --query 'services[0].taskDefinition' --output text)
                        echo "Currently running: $CURRENT"

                        aws ecs describe-task-definition --task-definition "$CURRENT" \
                            --query taskDefinition > current-td.json

                        jq --arg IMG "$REGISTRY/$REPOSITORY:$IMAGE_TAG" \
                           '.containerDefinitions[0].image = $IMG
                            | del(.taskDefinitionArn, .revision, .status, .requiresAttributes,
                                  .compatibilities, .registeredAt, .registeredBy)' \
                           current-td.json > new-td.json

                        NEW=$(aws ecs register-task-definition --cli-input-json file://new-td.json \
                            --query 'taskDefinition.taskDefinitionArn' --output text)
                        echo "New task definition: $NEW"

                        aws ecs update-service --cluster $CLUSTER --service $SERVICE \
                            --task-definition "$NEW" > /dev/null

                        aws ecs wait services-stable --cluster $CLUSTER --services $SERVICE

                        # The circuit breaker can roll back and still leave the service "stable",
                        # so confirm the new version is really the one running.
                        NOW=$(aws ecs describe-services --cluster $CLUSTER --services $SERVICE \
                            --query 'services[0].taskDefinition' --output text)
                        if [ "$NOW" != "$NEW" ]; then
                            echo "Deployment was rolled back to $NOW"
                            exit 1
                        fi
                        echo "Deployed $IMAGE_TAG successfully"
                    '''
                }
            }
        }
    }
}
