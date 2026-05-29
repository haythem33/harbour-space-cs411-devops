pipeline {
    agent any
    environment {
        IMAGE_TAG = "ttl.sh/haythem33:2h" 
        TARGET_VM = "docker" 
        TARGET_USER = "laborant" 
    }
    stages {
        stage('Build Docker Image') {
            steps {
                echo "Building Docker image..."
                sh "docker build -t ${IMAGE_TAG} ."
            }
        }
        stage('Push to Registry') {
            steps {
                echo "Pushing image to ttl.sh..."
                sh "docker push ${IMAGE_TAG}"
            }
        }
        stage('Deploy to Docker VM') {
            steps {
                echo "Deploying to ${TARGET_VM}..."
                sshagent(['target-ssh-key']) { 
                    sh """
                    ssh -o StrictHostKeyChecking=no ${TARGET_USER}@${TARGET_VM} 'docker rm -f myapp || true'
                    ssh -o StrictHostKeyChecking=no ${TARGET_USER}@${TARGET_VM} 'docker pull ${IMAGE_TAG}'
                    ssh -o StrictHostKeyChecking=no ${TARGET_USER}@${TARGET_VM} 'docker run -d --name myapp -p 4444:4444 ${IMAGE_TAG}'
                    """
                }
            }
        }
        stage('Verify Health Status') {
            steps {
                echo "Waiting 15 seconds for container to start..."
                sleep 15
                sshagent(['target-ssh-key']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ${TARGET_USER}@${TARGET_VM} "docker inspect --format='{{json .State.Health.Status}}' myapp | grep -q '\"healthy\"'"
                    """
                }
                echo "Deployment Verified and Healthy!"
            }
        }
    }
}
