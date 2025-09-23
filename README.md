# CI/CD Demo: GitHub Actions (CI) + Jenkins (CD) + Docker + Helm + Kubernetes
Flow:
1) GitHub Actions test -> build & push image (tag theo short SHA, nếu tag vX.Y.Z thì gắn thêm tag đó).
2) Sau khi push thành công trên nhánh main: Trigger Jenkins.
3) Jenkins dùng Helm deploy lên K8s (namespace theo ENV).

Secrets cần trên GitHub:
- DOCKERHUB_USERNAME
- DOCKERHUB_TOKEN
- JENKINS_URL (vd: https://jenkins.example.com)
- JENKINS_USER
- JENKINS_API_TOKEN
- JENKINS_JOB (tên job Jenkins, vd: Deploy-Max-Phan)

Credentials cần trên Jenkins:
- kubeconfig-eks (Secret file) chứa kubeconfig của cluster.

Local dev:
  python3 -m venv .venv && source .venv/bin/activate
  pip install -r requirements.txt -r requirements-dev.txt
  uvicorn app.main:app --reload --port 8080
