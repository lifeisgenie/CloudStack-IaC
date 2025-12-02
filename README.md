# CloudStack-IaC  
**CloudStack 기반 Kubernetes 클러스터 자동 구축 및 DevOps 환경 통합 (Terraform + Ansible + Kubernetes)**

## 프로젝트 개요

본 프로젝트는 **Infrastructure as Code(IaC)** 기반으로 CloudStack IaaS 환경에서  
쿠버네티스 클러스터를 자동 생성하고, 그 위에 **Jenkins / GitLab / Private Docker Registry**가 운영되는  
**DevOps CI/CD 파이프라인**을 구축하는 것을 목표로 한다.

전체 자동화 과정은 다음 흐름으로 구성된다:

> **Terraform → Ansible → Kubernetes → DevOps → CI/CD**  
> VM 생성부터 애플리케이션 배포까지 풀 자동화가 구현된 엔드-투-엔드 DevOps 파이프라인

## Architecture
![Architecture](./images/architecture.png)

# 전체 구축 흐름

## Terraform — CloudStack 인프라 자동 생성
- Kubernetes Master VM 1대
- Worker VM 2대
- Jenkins / GitLab / Registry를 위한 Port Forwarding Rule 자동 생성
  - Jenkins → 30880 → 8080
  - GitLab → 30022 → 22, 30080 → 80
  - Registry → 30500 → 5000
- CloudStack Isolated Network 내부에서 VM 간 통신 구성
- terraform output 으로 Master/Worker/Port 정보 자동 출력

👉 결과: VM + 네트워크 + 포트포워딩까지 완전 자동화된 인프라 생성

## Ansible — Kubernetes 클러스터 자동 구성
- Docker / containerd 설치
- swap 비활성화, 커널 매개변수(br_netfilter) 설정
- kubeadm/kubelet/kubectl 설치
- kubeadm init 실행하여 Master 초기화
- join token 추출 후 Worker 자동 조인
- Calico CNI 설치 (Pod 네트워크 구성)
- MetalLB 설치 및 L2 모드 IP 풀 설정

👉 결과: 직접 명령어 입력하지 않아도 Kubernetes 클러스터 완전 자동 구축

## Kubernetes — DevOps 서비스 배포

### 배포된 서비스
| 서비스                        | 노출 방식        | External IP (MetalLB) | NodePort      |
| -------------------------- | ------------ | --------------------- | ------------- |
| **Jenkins (CI)**           | LoadBalancer | **192.168.100.230**   | 32080         |
| **GitLab (SCM)**           | LoadBalancer | **192.168.100.231**   | 32081 / 32022 |
| **Private Registry (TLS)** | LoadBalancer | **192.168.100.232**   | 32500         |

### 주요 기능
- GitLab, Jenkins, Registry 모두 PVC로 데이터 영속화
- Registry는 Pod 내에서 CA + server cert 자동 생성
- 각 노드(containerd + docker)에 CA 복사 → TLS 신뢰 구조 구성 → Private Registry 이미지를 Pod에서 정상 Pull 가능

👉 결과: 쿠버네티스 네이티브 DevOps 환경 완성

## CI/CD 파이프라인 구축

### CI/CD Flow

```
Developer
   |
   v
GitLab (Push Event)
   |
   |  Webhook
   v
Jenkins (Pipeline 실행)
   |
   |  SSH Remote Build
   v
K8s Master Node
   |
   |  Docker Build → Push
   v
Docker Registry
   |
   |  kubectl apply 자동 수행
   v
Kubernetes Cluster (testapp Pod 업데이트)
```

### GitLab → Jenkins Webhook 연동
- GitLab 프로젝트 내 Webhook에 Jenkins URL 등록
- Secret Token 기반 보안 검증
- Push 이벤트 시 Jenkins Job 자동 실행

### Jenkins Pipeline 구성 (Jenkinsfile)
1. GitLab에서 소스 체크아웃
2. SSH로 Kubernetes Master에 접속
3. Docker build → Private Registry push
4. kubectl apply로 배포 업데이트
5. kubectl rollout status로 성공 여부 확인

👉 GitLab에 커밋만 하면 빌드 → 이미지 푸시 → 배포까지 자동 처리됨

## 테스트 애플리케이션(Nginx 기반 정적 HTML) 배포

### 디렉토리 구조
```
testapp/
 ├── src/index.html
 ├── Dockerfile
 ├── Jenkinsfile
 └── k8s/
      ├── deployment.yaml
      └── service.yaml
```

- MetalLB External IP로 서비스 확인: `curl http://<EXTERNAL-IP>:8080`
- 출력: `<h1>HELLO from testapp (GitLab → Jenkins → K8s)</h1>`

👉 실제 CI/CD 파이프라인이 정상 동작함을 시각적으로 확인

# 최종 요약

| 단계 | 기술 | 내용 |
|------|-------|-------------|
| **1. IaC** | Terraform | CloudStack VM + Port Forwarding 자동 생성 |
| **2. 자동 설정** | Ansible | Kubernetes 설치, Calico CNI, MetalLB 구성 |
| **3. DevOps 배포** | Kubernetes | Jenkins, GitLab, Registry Pod 배포 |
| **4. CI/CD 구성** | GitLab + Jenkins | Webhook Pipeline 자동 실행 |
| **5. 배포 자동화** | K8s Rollout | 이미지 Push → Rolling Update |
