pipeline {
  agent any

  parameters {
    string(name: 'IMAGE', defaultValue: 'changeme/max-phan-api', description: 'Container image repo')
    string(name: 'IMAGE_TAG', defaultValue: 'sha-xxxxxxx', description: 'Image tag to deploy')
    choice(name: 'ENV', choices: ['dev', 'staging', 'prod'], description: 'Target environment/namespace')
  }

  environment {
    // kubeconfig-eks: Secret file credential id trong Jenkins
    KUBECONFIG = credentials('kubeconfig-eks')
  }

  stages {
    stage('Tools') {
      steps {
        sh '''#!/usr/bin/env bash
          set -euo pipefail

          if ! command -v kubectl >/dev/null 2>&1; then
            echo "Installing kubectl..."
            curl -sSL -o kubectl https://dl.k8s.io/release/$(curl -sSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
            chmod +x kubectl && sudo mv kubectl /usr/local/bin/
          fi

          if ! command -v helm >/dev/null 2>&1; then
            echo "Installing helm..."
            curl -sSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
          fi

          kubectl version --client=true
          helm version
        '''
      }
    }

    stage('Deploy via Helm') {
      steps {
        sh '''#!/usr/bin/env bash
          set -euo pipefail

          CHART="helm/fastapi-service"
          RELEASE="max-phan-${ENV}"
          NAMESPACE="${ENV}"

          kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$NAMESPACE"

          helm upgrade --install "$RELEASE" "$CHART" \
            --namespace "$NAMESPACE" \
            --set image.repository="${IMAGE}" \
            --set image.tag="${IMAGE_TAG}" \
            --set app.env="${ENV}"

          echo "Deployed $IMAGE:$IMAGE_TAG to namespace=$NAMESPACE"
        '''
      }
    }
  }
}
