pipeline {
  agent any
  stages {
    stage('Print Branch') {
      steps {
        echo "Running on branch: ${env.BRANCH_NAME}"
      }
    }
  }
     post {
        success {
            slackSend(message: "Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' succeeded on ${env.NODE_NAME}")
        }
        failure {
            slackSend(message: "Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' failed. Check console output: ${env.BUILD_URL}")
        }
    }
}

