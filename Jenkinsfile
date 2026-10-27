pipeline {
    agent any

    environment {
        IMAGE = 'orders-api'
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
                dir('app') {
                    sh 'docker build --platform linux/amd64 -t ${IMAGE}:build-${BUILD_NUMBER} .'
                }
            }
        }
    }
}
