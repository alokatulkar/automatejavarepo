pipeline {
    agent any

    tools {
        maven 'Maven'
    }

    environment {
        DOCKER_IMAGE = "alok2804/java-app"
        AWS_REGION = "ap-south-1"
        CLUSTER_NAME = "ekscluster"
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

        stage('Terraform EKS') {
            steps {
                dir('terraform/eks') {
                    sh 'terraform init'
                    sh 'terraform plan'
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Configure Kubeconfig') {
            steps {
                sh 'aws eks --region ap-south-1 update-kubeconfig --name ekscluster'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} ."
            }
        }

        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                    echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}
                    docker logout
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes using Helm') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aws-creds',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    sh '''
                    export AWS_DEFAULT_REGION=$AWS_REGION

                    aws sts get-caller-identity

                    aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

                    helm upgrade --install java-app ./helm \
                      --set image.repository=alok2804/java-app \
                      --set image.tag=${BUILD_NUMBER} \
                      --namespace default \
                      --create-namespace
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                sh 'kubectl get nodes'
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully ✅'
        }
        failure {
            echo 'Pipeline failed ❌'
        }
    }
}