pipeline {
    agent any

    stages {
        stage('Build and test') {
            steps {
                dir('app') {
                    sh 'mvn -B verify'
                }
            }
        }
    }
}
