pipeline {
    agent any

    triggers {
        // Every day at 18:00 (the server's time zone)
        cron('0 18 * * *')
    }

    environment {
        AWS_REGION       = 'eu-west-2'
        ALERTS_TOPIC_ARN = 'arn:aws:sns:eu-west-2:743978812281:shipit-dev-alerts'
    }

    stages {
        stage('Check for billable resources') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aws-jenkins-ecr',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    script {
                        def code = sh(script: './scripts/bash/check-billing.sh', returnStatus: true)

                        if (code == 1) {
                            sh """aws sns publish --topic-arn "\$ALERTS_TOPIC_ARN" \\
                                  --subject "Shipit: billable AWS resources still running" \\
                                  --message "The daily billing check found resources that cost money by the hour. See ${env.BUILD_URL}console" """
                            error('Billable resources are still running')
                        } else if (code != 0) {
                            sh """aws sns publish --topic-arn "\$ALERTS_TOPIC_ARN" \\
                                  --subject "Shipit: billing check could not run" \\
                                  --message "The check itself failed (exit code ${code}), so nothing is confirmed clear. See ${env.BUILD_URL}console" """
                            error("Billing check could not run (exit code ${code})")
                        }
                    }
                }
            }
        }
    }
}
