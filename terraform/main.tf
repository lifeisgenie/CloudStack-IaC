# === Data sources ===

data "cloudstack_template" "ubuntu" {
  template_filter = "featured"

  filter {
    name  = "name"
    value = var.template_name
  }
}

data "cloudstack_zone" "dku" {
  filter {
    name  = "name"
    value = var.zone_name
  }
}

data "cloudstack_service_offering" "medium" {
  filter {
    name  = "name"
    value = var.service_offering_name
  }
}

# === Isolated Network + Egress Rule ===

resource "cloudstack_network" "isolated" {
  name         = "terraform-${var.student_id}"
  display_text = "Terraform Isolated Network"
  cidr         = var.network_cidr

  network_offering = "DefaultIsolatedNetworkOfferingWithSourceNatService"
  zone             = data.cloudstack_zone.dku.name
}

resource "cloudstack_egress_firewall" "egress_all" {
  network_id = cloudstack_network.isolated.id

  rule {
    cidr_list = ["0.0.0.0/0"]
    protocol  = "all"
  }
}

# === Public IP for Port Forwarding ===

resource "cloudstack_ipaddress" "public" {
  network_id = cloudstack_network.isolated.id
}

# === 공통 cloud-init user_data ===

locals {
  base_cloud_init = <<-EOF
    #cloud-config
    password: ubuntu
    chpasswd: { expire: False }
    ssh_pwauth: True
  EOF
}

# === Master / Worker Instance ===

resource "cloudstack_instance" "master" {
  count = var.master_count

  name             = "master-${var.student_id}-${count.index + 1}"
  service_offering = data.cloudstack_service_offering.medium.id
  network_id       = cloudstack_network.isolated.id
  template         = data.cloudstack_template.ubuntu.id
  zone             = data.cloudstack_zone.dku.name

  root_disk_size = var.root_disk_size
  expunge        = true
  user_data      = local.base_cloud_init
}

# Worker 개수 = worker_roles 길이
resource "cloudstack_instance" "worker" {
  count = length(var.worker_roles)

  name             = "worker-${var.student_id}-${count.index + 1}"
  service_offering = data.cloudstack_service_offering.medium.id
  network_id       = cloudstack_network.isolated.id
  template         = data.cloudstack_template.ubuntu.id
  zone             = data.cloudstack_zone.dku.name

  root_disk_size = var.root_disk_size
  expunge        = true
  user_data      = local.base_cloud_init
}

# === Service Port Forwarding (Jenkins, GitLab, Registry) ===

# 반복되는 포트포워딩 정보를 리스트로 정의
locals {
  service_forward_rules = [
    { name = "jenkins_http", private = 8080, public = 30880 }, # Jenkins
    { name = "gitlab_ssh",   private = 22,   public = 30022 }, # GitLab SSH
    { name = "gitlab_http",  private = 80,   public = 30080 }, # GitLab HTTP
    { name = "registry",     private = 5000, public = 30500 }, # Docker Registry
  ]
}

# 모든 서비스는 worker[0]로 포워딩 (ingress 역할)
resource "cloudstack_port_forward" "services" {
  for_each     = { for r in local.service_forward_rules : r.name => r }
  ip_address_id = cloudstack_ipaddress.public.id

  forward {
    protocol           = "tcp"
    private_port       = each.value.private
    public_port        = each.value.public
    virtual_machine_id = cloudstack_instance.worker[0].id
  }
}

# === SSH Port Forwarding (Master/Workers) ===

# Master: 3022, Worker: 3023, 3024, ... 규칙 생성용 locals
locals {
  ssh_rules = concat(
    [
      for idx, inst in cloudstack_instance.master :
      {
        name   = "master_${idx + 1}"
        vm_id  = inst.id
        public = 3022 + idx
      }
    ],
    [
      for idx, inst in cloudstack_instance.worker :
      {
        name   = "worker_${idx + 1}"
        vm_id  = inst.id
        public = 3023 + idx
      }
    ]
  )
}

resource "cloudstack_port_forward" "ssh" {
  for_each      = { for r in local.ssh_rules : r.name => r }
  ip_address_id = cloudstack_ipaddress.public.id

  forward {
    protocol           = "tcp"
    private_port       = 22
    public_port        = each.value.public
    virtual_machine_id = each.value.vm_id
  }
}

# === Firewall Rules (모든 포트 자동 허용) ===

# 서비스 포트 + SSH 포트를 모두 합친 리스트
locals {
  firewall_ports = concat(
    [for r in local.service_forward_rules : r.public],
    [for r in local.ssh_rules           : r.public]
  )
}

resource "cloudstack_firewall" "public_fw" {
  ip_address_id = cloudstack_ipaddress.public.id

  # 각 포트에 대해 rule 블록 자동 생성
  dynamic "rule" {
    for_each = local.firewall_ports

    content {
      cidr_list = ["0.0.0.0/0"]
      protocol  = "tcp"
      ports     = [tostring(rule.value)]
    }
  }
}

# === Ansible Inventory 생성을 위한 locals ===

locals {
  masters = [
    for idx, inst in cloudstack_instance.master : {
      name         = inst.name
      ansible_host = cloudstack_ipaddress.public.ip_address
      port         = 3022 + idx
    }
  ]

  workers = [
    for idx, inst in cloudstack_instance.worker : {
      name         = inst.name
      ansible_host = cloudstack_ipaddress.public.ip_address
      port         = 3023 + idx
      role         = var.worker_roles[idx]
    }
  ]
}

# === Ansible inventory 파일 생성 ===

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory/hosts.ini"

  content = templatefile("${path.module}/templates/hosts.ini.tftpl", {
    masters = local.masters
    workers = local.workers
  })
}