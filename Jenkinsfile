pipeline {
    agent any
    tools {
        go '1.24.1' 
    }
    environment {
        TARGET_HOST = 'target'
        APP_DIR = '/opt/myapp'
    }

    stages {
        stage('Build') {
            steps {
                echo 'Building Go application...'
                // Compiles main.go into an executable
                sh 'go build -o binary-app main.go' 
            }
        }
        
        stage('Deploy to Target') {
            steps {
                echo 'Shipping binary and systemd unit to target...'
                // Uses the key you created to log in as 'laborant'
                sshagent(['target-ssh-key']) { 
                    sh """
                    # 1. Idempotency: Create the non-root user if it doesn't exist
                    ssh -o StrictHostKeyChecking=no laborant@${TARGET_HOST} 'sudo id -u myapp &>/dev/null || sudo useradd -m myapp'
                    
                    # 2. Idempotency: Create directory and set ownership
                    ssh -o StrictHostKeyChecking=no laborant@${TARGET_HOST} 'sudo mkdir -p ${APP_DIR} && sudo chown myapp:myapp ${APP_DIR}'
                    
                    # 3. SCP the files to laborant's home directory first (due to permissions)
                    scp -o StrictHostKeyChecking=no binary-app laborant@${TARGET_HOST}:/home/laborant/binary-app
                    scp -o StrictHostKeyChecking=no myapp.service laborant@${TARGET_HOST}:/home/laborant/myapp.service
                    
                    # 4. Move files to correct locations, set permissions, and restart service
                    ssh -o StrictHostKeyChecking=no laborant@${TARGET_HOST} 'sudo mv /home/laborant/binary-app ${APP_DIR}/binary-app && sudo mv /home/laborant/myapp.service /etc/systemd/system/myapp.service'
                    ssh -o StrictHostKeyChecking=no laborant@${TARGET_HOST} 'sudo chmod +x ${APP_DIR}/binary-app && sudo chown myapp:myapp ${APP_DIR}/binary-app'
                    ssh -o StrictHostKeyChecking=no laborant@${TARGET_HOST} 'sudo systemctl daemon-reload && sudo systemctl enable myapp.service && sudo systemctl restart myapp.service'
                    """
                }
            }
        }
        
        stage('Health Check Gate') {
            steps {
                echo 'Polling for expected JSON response...'
                // Stretch Goal: Post-deploy health-check gate with retries
                timeout(time: 1, unit: 'MINUTES') {
                    retry(12) { 
                        sleep 5
                        sh "curl -fsS http://${TARGET_HOST}:4444/ | grep '\"Name\":\"Hello\"'"
                    }
                }
                echo "Health check passed! App is serving traffic."
            }
        }
    }
}