pipeline {
    agent any

    environment {
        IMAGE_NAME = "trend"
        IMAGE_TAG  = "v4"
        ECR_REPO   = "524781515606.dkr.ecr.us-west-2.amazonaws.com/trend-repo"
        KUBE_CONFIG_PATH = "/var/lib/jenkins/.kube/config"
        AWS_REGION = "us-west-2"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'dev', url: 'https://github.com/singh-ajmer-git/trend.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                    sh "docker images"
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    // Login to AWS ECR
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}"

                    // Tag and push
                    sh "docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}"
                    sh "docker push ${ECR_REPO}:${IMAGE_TAG}"
                    sh "docker images"
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    // Update kubeconfig to use EKS cluster
                    sh "aws eks update-kubeconfig --region ${AWS_REGION} --name trend-eks"

                    // Apply deployment
                    sh "kubectl apply -f deployment.yaml"
		    sh "kubectl apply -f service.yaml"	
                    sh "kubectl get deployment"
                    sh "kubectl get svc"
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully! 🎉"
        }
        failure {
            echo "Pipeline failed ❌"
        }
    }
}
