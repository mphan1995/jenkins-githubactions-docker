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

          echo "== Disk && Workspace info =="
          df -h || true
          echo "BIN=$BIN"
          echo "CACHE=$CACHE"

          echo "== Install kubectl =="
          KVER=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
          curl $CURL_OPTS -o "$BIN/kubectl.tmp" "https://dl.k8s.io/release/${KVER}/bin/${OS}/${ARCH}/kubectl"
          mv "$BIN/kubectl.tmp" "$BIN/kubectl"
          chmod +x "$BIN/kubectl"

          echo "== Install helm =="
          HELM_VER=$(curl -fsSL https://api.github.com/repos/helm/helm/releases/latest | grep -m1 '"tag_name"' | cut -d '"' -f4)

          # Cách 1: tải về file .tgz vào CACHE
          if ! curl $CURL_OPTS -o "$CACHE/helm.tgz" "https://get.helm.sh/helm-${HELM_VER}-${OS}-${ARCH}.tar.gz"; then
            echo "WARN: download to file failed, retry piping to tar..."
            # Cách 2: pipe trực tiếp sang tar (không ghi file trung gian)
            curl -LfsS "https://get.helm.sh/helm-${HELM_VER}-${OS}-${ARCH}.tar.gz" | tar -xz -C "$CACHE" || {
              echo "ERROR: cannot download/extract helm"
              exit 1
            }
          else
            tar -xzf "$CACHE/helm.tgz" -C "$CACHE"
          fi

          # di chuyển binary
          if [ -f "$CACHE/${OS}-${ARCH}/helm" ]; then
            mv "$CACHE/${OS}-${ARCH}/helm" "$BIN/helm"
          elif [ -f "$CACHE/helm" ]; then
            mv "$CACHE/helm" "$BIN/helm"
          else
            echo "ERROR: helm binary not found after extraction"
            ls -lah "$CACHE" || true
            exit 1
          fi
          chmod +x "$BIN/helm"

          echo "== Tool versions =="
          "$BIN/kubectl" version --client
          "$BIN/helm" version
        '''
      }
    }


    stage('Deploy via Helm') {
      environment { PATH = "${WORKSPACE}/bin:${PATH}" }
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
  } // end stages
} // end pipeline
