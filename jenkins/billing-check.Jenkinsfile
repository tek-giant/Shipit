pipeline {
    agent any

    triggers {
        // Every day at 18:00 (the server's time zone)
        cron('0 18 * * *')
    }

    environment {
        AWS_REGION = 'eu-west-2'
    }

    stages {
        stage('Check for billable resources') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aws-jenkins-ecr',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    sh './scripts/bash/check-billing.sh'
                }
            }
        }
    }

    post {
        failure {
            echo 'Billable resources are still running, or the check could not run. See the log above.'
        }
    }
}
