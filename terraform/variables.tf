# 공통 식별자 (네트워크/VM 이름에 사용)
variable "student_id" {
  description = "학번 (예: 32200000)"
  type        = string
}

# 네트워크 CIDR (Isolated Network)
variable "network_cidr" {
  description = "Kubernetes 클러스터용 Isolated Network CIDR"
  type        = string
  default     = "192.168.100.0/24"
}

# CloudStack 리소스 이름
variable "service_offering_name" {
  description = "VM Service Offering 이름 (예: Large)"
  type        = string
  default     = "Large"
}

variable "template_name" {
  description = "Ubuntu Template 이름"
  type        = string
  default     = "Ubuntu_24.04"
}

variable "zone_name" {
  description = "CloudStack Zone 이름"
  type        = string
  default     = "DKU"
}

# VM 스펙
variable "root_disk_size" {
  description = "루트 디스크 크기 (GB)"
  type        = number
  default     = 40
}

variable "master_count" {
  description = "Kubernetes Master VM 개수"
  type        = number
  default     = 1
}

variable "worker_count" {
  description = "Kubernetes Worker VM 개수"
  type        = number
  default     = 2
}

# Worker 노드 역할에 따라 개수 자동 결정
variable "worker_roles" {
  description = "각 worker 노드 역할 (jenkins, gitlab, registry 등)"
  type        = list(string)
  default     = ["jenkins", "gitlab"]  # worker-1, worker-2
}