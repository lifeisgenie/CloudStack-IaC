output "public_ip" {
  description = "외부에서 접근할 Public IP"
  value       = cloudstack_ipaddress.public.ip_address
}

output "master_private_ips" {
  description = "Kubernetes Master 노드 Private IP 목록"
  value       = cloudstack_instance.master[*].ip_address
}

output "worker_private_ips" {
  description = "Kubernetes Worker 노드 Private IP 목록"
  value       = cloudstack_instance.worker[*].ip_address
}

output "all_private_ips" {
  description = "클러스터 전체 노드 Private IP (Master + Worker)"
  value       = concat(
    cloudstack_instance.master[*].ip_address,
    cloudstack_instance.worker[*].ip_address
  )
}

output "ansible_master_ssh" {
  description = "Ansible용 Master SSH 포트 정보"
  value       = local.masters
}

output "ansible_worker_ssh" {
  description = "Ansible용 Worker SSH 포트 및 역할 정보"
  value       = local.workers
}