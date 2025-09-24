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
          CACHE="$WORKSPACE/.cache/tools"
          mkdir -p "$BIN" "$CACHE"

          OS=linux
          ARCH=amd64
          CURL_OPTS="-LfsS --retry 5 --retry-delay 2 --connect-timeout 20 --max-time 300"

          echo "== Disk & Net info =="
          df -h || true
          getent hosts dl.k8s.io || true
          getent hosts get.helm.sh || true

          echo "== Install kubectl =="
          KVER=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
          echo "Kubernetes stable: $KVER"
          curl $CURL_OPTS -o "$BIN/kubectl" "https://dl.k8s.io/release/${KVER}/bin/${OS}/${ARCH}/kubectl"
          chmod +x "$BIN/kubectl"

          echo "== Install helm =="
          HELM_VER=$(curl -fsSL https://api.github.com/repos/helm/helm/releases/latest | grep -m1 '"tag_name"' | cut -d '"' -f4 || true)
          HELM_VER=${HELM_VER:-v3.19.0}
          echo "Helm version: $HELM_VER"
          # tải và giải nén trực tiếp, tránh ghi file tạm
          curl -LfsS "https://get.helm.sh/helm-${HELM_VER}-${OS}-${ARCH}.tar.gz" | tar -xz -C "$CACHE"
          mv "$CACHE/${OS}-${ARCH}/helm" "$BIN/helm"
          chmod +x "$BIN/helm"

          echo "== Install AWS CLI v2 =="
          curl $CURL_OPTS -o "$CACHE/awscliv2.zip" "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
          unzip -q -o "$CACHE/awscliv2.zip" -d "$CACHE"
          # cài vào thư mục của workspace, bin trỏ vào $WORKSPACE/bin
          "$CACHE/aws/install" -i "$WORKSPACE/.aws-cli" -b "$BIN" || true

          echo "== Versions =="
          "$BIN/kubectl" version --client
          "$BIN/helm" version
          "$BIN/aws" --version
        '''
      }
    }


    stage('Deploy via Helm') {
      environment {
        PATH = "${WORKSPACE}/bin:${PATH}"
        AWS_DEFAULT_REGION = "ap-southeast-1"   // đổi nếu khác
      }
      steps {
        withCredentials([[ $class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'kubeconfig-eks' ]]) {
          sh '''#!/usr/bin/env bash
            set -euo pipefail

            echo "Using AWS identity:"
            aws sts get-caller-identity || { echo "AWS CLI not configured"; exit 1; }

            echo "Kube contexts (quick check):"
            kubectl config get-contexts || true

            CHART="helm/fastapi-service"
            RELEASE="max-phan-${ENV}"
            NAMESPACE="${ENV}"

            # Optional: xác thực cluster trước khi deploy (giúp debug nhanh)
            echo "Cluster info:"
            kubectl cluster-info

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


  } // end stages
} // end pipeline
