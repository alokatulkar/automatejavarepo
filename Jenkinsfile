pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "alok2804/java-app"
    }

    tools {
        maven 'Maven'
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/alokatulkar/automatejavarepo.git'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }


        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${DOCKER_IMAGE}:latest .'
            }
        }

        stage('Push to DockerHub') {
    steps {
        script {
            withCredentials([usernamePassword(
                credentialsId: 'dockerhub-creds',
                usernameVariable: 'USER',
                passwordVariable: 'PASS'
            )]) {
                sh '''
                echo "$PASS" | docker login -u "$USER" --password-stdin
                docker push alok2804/java-app:latest
                docker logout
                '''
            }
        }
    }
}

         stage('Deploy to Kubernetes using Helm') {
            steps {
                sh '''
                helm upgrade --install ${HELM_RELEASE} ./helm \
                --set image.repository=${DOCKER_IMAGE} \
                --set image.tag=${BUILD_NUMBER} \
                --namespace ${KUBE_NAMESPACE} \
                --create-namespace
                '''
            }
        }
    }

    post {
        always {
            echo 'Pipeline completed'
        }
        success {
            echo 'Deployment successful 🚀'
        }
        failure {
            echo 'Pipeline failed ❌'
        }
    }
}