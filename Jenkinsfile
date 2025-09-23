pipeline {
  agent any

  parameters {
    string(name: 'IMAGE', defaultValue: 'thonglinux/max-phan-api', description: 'Container image repo (vd: yourname/max-phan-api)')
    string(name: 'IMAGE_TAG', defaultValue: 'test', description: 'Image tag to deploy (vd: sha-abc1234 hoặc test)')
    choice(name: 'ENV', choices: ['dev', 'staging', 'prod'], description: 'Target environment/namespace')
  }

  environment {
    // Credential kiểu "Secret file" chứa kubeconfig, ID phải khớp trong Jenkins Credentials
    KUBECONFIG = credentials('kubeconfig-eks')
  }

  stages {

    stage('Tools') {
      steps {
        sh '''#!/usr/bin/env bash
          set -euo pipefail

          BIN="$WORKSPACE/bin"
          mkdir -p "$BIN"

          OS=linux
          ARCH=amd64

          echo "== Install kubectl =="
          KVER=$(curl -sSL https://dl.k8s.io/release/stable.txt)
          curl -sSL -o "$BIN/kubectl" "https://dl.k8s.io/release/${KVER}/bin/${OS}/${ARCH}/kubectl"
          chmod +x "$BIN/kubectl"

          echo "== Install helm =="
          HELM_VER=$(curl -sSL https://api.github.com/repos/helm/helm/releases/latest | grep -m1 tag_name | cut -d '"' -f4)
          curl -sSL -o /tmp/helm.tgz "https://get.helm.sh/helm-${HELM_VER}-${OS}-${ARCH}.tar.gz"
          tar -xf /tmp/helm.tgz -C /tmp
          mv "/tmp/${OS}-${ARCH}/helm" "$BIN/helm"
          chmod +x "$BIN/helm"

          echo "== Tool versions =="
          "$BIN/kubectl" version --client
          "$BIN/helm" version
        '''
      }
    }

    stage('Deploy via Helm') {
      // đảm bảo dùng kubectl/helm vừa cài
      environment {
        PATH = "${WORKSPACE}/bin:${PATH}"
      }
      steps {
        sh '''#!/usr/bin/env bash
          set -euo pipefail

          echo "IMAGE=${IMAGE}"
          echo "IMAGE_TAG=${IMAGE_TAG}"
          echo "ENV=${ENV}"

          CHART="helm/fastapi-service"
          RELEASE="max-phan-${ENV}"
          NAMESPACE="${ENV}"

          # Tạo namespace nếu chưa có
          kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$NAMESPACE"

          # Deploy/Update
          helm upgrade --install "$RELEASE" "$CHART" \
            --namespace "$NAMESPACE" \
            --set image.repository="${IMAGE}" \
            --set image.tag="${IMAGE_TAG}" \
            --set app.env="${ENV}"

          echo "Deployed $IMAGE:$IMAGE_TAG to namespace=$NAMESPACE"
        '''
      }
    }

  } // end stages
} // end pipeline
