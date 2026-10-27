pipeline {
    agent any

    environment {
        REGISTRY           = '743978812281.dkr.ecr.eu-west-2.amazonaws.com'
        REPOSITORY         = 'shipit/orders-api'
        AWS_DEFAULT_REGION = 'eu-west-2'
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
    }
}
