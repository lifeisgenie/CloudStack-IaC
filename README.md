# CloudStack-IaC
**CloudStack 기반 쿠버네티스 클러스터 자동 구축 및 DevOps 환경 통합 (Terraform + Ansible + Kubernetes)**

## 프로젝트 개요

CloudStack 환경에서 **Infrastructure as Code (IaC)** 방식을 활용하여 
쿠버네티스 클러스터를 자동 프로비저닝하고, **Jenkins / GitLab / Docker Registry**로 구성된  
DevOps CI/CD 환경을 통합 구축한 프로젝트입니다.

> Terraform → Ansible → Kubernetes → DevOps → CI/CD 까지 이어지는 **엔드-투-엔드 자동화 파이프라인**

## 실행 순서

### Terraform을 활용한 CloudStack 인프라 프로비저닝

- Master/Worker 자동 설치 및 `kubeadm join` 수행
- Calico 또는 Cilium CNI 구성
- MetalLB (L2 모드) 설정으로 외부 접근 서비스 제공

### Ansible을 활용한 Kubernetes 클러스터 구성

- Jenkins, GitLab, Docker Registry 배포
- 각 서비스는 LoadBalancer IP로 외부 노출
- Secret 및 PVC를 이용한 데이터 영속화 구성

### Kubernetes를 활용한 DevOps 환경 배포

- GitLab 프로젝트 생성 및 WebHook으로 Jenkins 연결
- 커밋 시 Jenkins Pipeline 자동 실행
- Docker 이미지 빌드 → Registry 푸시 → K8s 배포

### CI/CD 파이프라인 검증
