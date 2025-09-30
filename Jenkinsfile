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
            slackSend(channel: '#jenkins-builds', color: 'good', message: "✅ Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' succeeded on ${env.NODE_NAME}")
        }
        failure {
            slackSend(channel: '#jenkins-builds', color: 'danger', message: "❌ Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' failed. Check console output: ${env.BUILD_URL}")
        }
    }
}

