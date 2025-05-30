pipeline {
    agent { label 'agent-vm1' }

    tools {
        maven 'Maven 3.9.6'
    }
    
    parameters {
        string(name: 'commitMessage', defaultValue: '', description: 'Git commit message from webhook')
    }

    environment {
        DOCKER_CRED_ID = "Dockerhub-cred"
        GIT_CRED_ID = "Github-cred"
        SONAR_CRED_ID = "Sonar-cred"
        TIMESTAMP = "${new Date().format('yyyyMMddHHmmss')}"
    }

    stages {
        stage('Checkout') {
            steps {
                git credentialsId: "${GIT_CRED_ID}", url: 'https://github.com/voducanh21/microservices-project.git', branch: 'master'
            }
        }
        
        stage('Skip Check') {
            steps {
                script {
                    echo "🔎 Checking commit message: ${params.commitMessage}"
                    if (params.commitMessage.contains("[skip-ci]")) {
                        echo "🚫 Skipping build due to [skip-ci]"
                        currentBuild.result = 'SUCCESS'
                        return
                    }
                }
            }
        }

        stage('Trivy FS Scan and Export for SonarQube') {
            steps {
                script {
                    def backendServices = ['api-gateway', 'product-service', 'order-service', 'inventory-service']

                    backendServices.each { svc ->
                        dir(svc) {
                            echo "🔍 Running Trivy filesystem scan for ${svc}..."
                            sh 'docker run --rm -v "$PWD:/app" -w /app aquasec/trivy fs --skip-files app/app.jar --format json --output trivy-result.json .'
                            sh "node ${env.WORKSPACE}/convert-trivy-to-sonarqube.js"
                        }
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def backendServices = ['api-gateway', 'product-service', 'order-service', 'inventory-service']

                    backendServices.each { svc ->
                        dir(svc) {
                            withSonarQubeEnv('SonarQube') {
                                withCredentials([string(credentialsId: "${SONAR_CRED_ID}", variable: 'SONAR_TOKEN')]) {
                                    sh "mvn clean verify sonar:sonar -DskipTests -Dsonar.token=${SONAR_TOKEN} -Dsonar.externalIssuesReportPaths=sonarqube-trivy.json"
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Build and Push All Services') {
            steps {
                script {
                    def services = [
                        [name: 'api-gateway', image: 'ducanhvo/api-gateway'],
                        [name: 'product-service', image: 'ducanhvo/product-service'],
                        [name: 'order-service', image: 'ducanhvo/order-service'],
                        [name: 'inventory-service', image: 'ducanhvo/inventory-service'],
                        [name: 'microservices-shop-frontend', image: 'ducanhvo/frontend']
                    ]

                    def yamlFileMap = [
                        'api-gateway'                : 'api-gateway.yml',
                        'product-service'            : 'product-service.yml',
                        'order-service'              : 'order-service.yml',
                        'inventory-service'          : 'inventory-service.yml',
                        'microservices-shop-frontend': 'frontend.yml'
                    ]

                    services.each { svc ->
                        def imageTag = "${svc.image}:${env.TIMESTAMP}"
                        def yamlPath = "k8s/manifests/applications/${yamlFileMap[svc.name]}"

                        dir(svc.name) {
                            if (!svc.name.contains('frontend')) {
                                sh 'mvn clean package -DskipTests'
                            }
                            sh "docker build -t ${imageTag} ."
                            withDockerRegistry([credentialsId: "${DOCKER_CRED_ID}", url: ""]) {
                                sh "docker push ${imageTag}"
                            }
                        }

                        // Update image tag in YAML
                        def yamlContent = readFile(file: yamlPath)
                        yamlContent = yamlContent.replaceAll(/image:\s+${svc.image}:.*/, "image: ${imageTag}")
                        writeFile file: yamlPath, text: yamlContent
                    }
                }
            }
        }

        stage('Trivy Security Scan') {
            steps {
                script {
                    def images = [
                        "ducanhvo/api-gateway:${env.TIMESTAMP}",
                        "ducanhvo/product-service:${env.TIMESTAMP}",
                        "ducanhvo/order-service:${env.TIMESTAMP}",
                        "ducanhvo/inventory-service:${env.TIMESTAMP}",
                        "ducanhvo/frontend:${env.TIMESTAMP}"
                    ]

                    def parallelStages = images.collectEntries { img ->
                        ["Scan ${img}": {
                            echo "🔐 Scanning ${img}..."
                            sh """
                              docker run --rm \
                                -v /home/ducanh/.trivy-cache:/root/.cache \
                                aquasec/trivy image \
                                --skip-version-check \
                                
                                --severity HIGH,CRITICAL \
                                --exit-code 0 \
                                #--ignore-unfixed \
                                --timeout 10m \
                                ${img} || true
                            """
                        }]
                    }

                    parallel parallelStages
                }
            }
        }

        stage('Commit YAML to Git') {
            steps {
                script {
                    sh """
                        git config user.name "Jenkins"
                        git config user.email "jenkins@localhost"

                        # Stage YAML file nếu có thay đổi
                        git add k8s/manifests/applications/*.yml || true

                        # Kiểm tra xem có thực sự thay đổi không
                        if ! git diff --cached --quiet; then
                            echo "Committing YAML changes..."
                            git commit -m "ci: update image tags to ${TIMESTAMP} [skip-ci]"
                            git push origin master
                        else
                            echo "✅ No YAML changes to commit"
                        fi
                    """
                }
            }
        }
    }
}
