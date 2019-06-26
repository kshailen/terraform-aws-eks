#
# Workstation External IP

data "http" "workstation-external-ip" {
  url = "http://ifconfig.me/ip"
}

locals {
  workstation-external-cidr = "${chomp(data.http.workstation-external-ip.body)}/32"
}
