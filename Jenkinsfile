pipeline {
    agent { label 'agent-01' }

    tools {
        maven 'Maven 3.9.6'
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
                    def commitMsg = sh(script: "git log -1 --pretty=%B", returnStdout: true).trim()
                    echo "🔎 Last commit message: ${commitMsg}"
                    if (commitMsg.contains("[skip-ci]")) {
                        echo "🚫 Skipping build due to [skip-ci]"
                        currentBuild.result = 'SUCCESS'
                        error("Build stopped due to [skip-ci]")
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
                                    sh "mvn clean verify sonar:sonar -DskipTests -Dsonar.token=${SONAR_TOKEN}"
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Build, Scan, and Push Services') {
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

                            // 🔨 Build image
                            sh "docker build -t ${imageTag} ."

                            // 🔍 Trivy Scan update
                            echo "🔐 Scanning image with Trivy: ${imageTag}"
                            sh """
                                trivy image --severity HIGH,CRITICAL --no-progress ${imageTag} || echo '⚠️ Trivy found vulnerabilities!'
                            """

                            // 🐳 Push image
                            withDockerRegistry([credentialsId: "${DOCKER_CRED_ID}", url: ""]) {
                                sh "docker push ${imageTag}"
                            }
                        }

                        // ✏️ Update manifest
                        def yamlContent = readFile(file: yamlPath)
                        yamlContent = yamlContent.replaceAll(/image:\s+${svc.image}:.*/, "image: ${imageTag}")
                        writeFile file: yamlPath, text: yamlContent
                    }
                }
            }
        }

        stage('Commit YAML to Git') {
            steps {
                script {
                    sh """
                        git config user.name "Jenkins"
                        git config user.email "jenkins@localhost"
                        git add k8s/manifests/applications/*.yml || true

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
