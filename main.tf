
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  #user_ocid        = var.user_ocid
  #fingerprint      = var.fingerprint
  #private_key_path = var.private_key_path
  region           = var.region
}

terraform {
  required_version = ">= 1.1"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.1.0" # Latest version as January 2022 = 2.1.0.
      # https://registry.terraform.io/providers/hashicorp/local/2.1.0
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0" # Latest version as January 2022 = 3.1.0.
      # https://registry.terraform.io/providers/hashicorp/random/3.1.0
    }    
  }
}

# Randoms
resource "random_string" "deploy_id" {
  length  = 4
  special = false
}

resource "oci_core_route_table" "postgress_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = var.postgresql_vcn
  display_name   = "postgreSQLRT-${random_string.deploy_id.result}"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = var.nat_gw_selected
  }
}

resource "oci_core_security_list" "psql_securitylist" {
  compartment_id = var.compartment_ocid
  vcn_id         = var.postgresql_vcn
  display_name   = "postgreSQL-seclist-${random_string.deploy_id.result}"

  egress_security_rules {
    protocol    = "6"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      max = "22"
      min = "22"
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      max = "5432"
      min = "5432"
    }
  }
}

locals {
  vcn_cidr = element(data.oci_core_vcn.postgresql_vcn.cidr_blocks, 0)
  # Future version may automate it.  Consider changing if clashes with existing subnet  this assume most examples use /24 and pick first 9 subnets ranges
  new_subnet_cidr= var.postgresql_subnet_cidr != "" ? var.postgresql_subnet_cidr : cidrsubnets(local.vcn_cidr,8, 8, 8, 8, 8, 8, 8, 8,12 )[8]
}


resource "oci_core_subnet" "postgreSQL_subnet" {
  cidr_block                 = local.new_subnet_cidr
  display_name               = "postgreSQL-Subnet-${random_string.deploy_id.result}"
  dns_label                  = "pstsqlsn${random_string.deploy_id.result}"
  security_list_ids          = [oci_core_security_list.psql_securitylist.id]
  compartment_id             = var.compartment_ocid
  vcn_id                     = var.postgresql_vcn
  route_table_id             = oci_core_route_table.postgress_rt.id
  dhcp_options_id            = data.oci_core_vcn.postgresql_vcn.default_dhcp_options_id
  prohibit_public_ip_on_vnic = true
}

module "arch-postgresql" {
  source                   = "./module-postgresql"
  tenancy_ocid             = var.tenancy_ocid
  availablity_domain_name  = var.availablity_domain_name
  compartment_ocid         = var.compartment_ocid
  use_existing_vcn         = true                               # usage of the external existing VCN
  create_in_private_subnet = true                               # usage of the private subnet
  postgresql_vcn           = var.postgresql_vcn # injecting myVCN
  postgresql_subnet        = oci_core_subnet.postgreSQL_subnet.id       # injecting private mySubnet 
  postgresql_password      = var.postgresql_password
  add_iscsi_volume         = var.add_iscsi_volume # adding iSCSI volume...
  iscsi_volume_size_in_gbs = var.iscsi_volume_size_in_gbs  # ... with 200 GB of size
  postgresql_version       = var.postgresql_version
  region=var.region
  user_ocid=""
  fingerprint=""
  private_key_path=""
  
  # OCPUs & memory for flex shape in master node (aarch64/OL8).
  postgresql_instance_shape             = var.postgresql_instance_shape
  postgresql_instance_flex_shape_ocpus  = var.postgresql_instance_flex_shape_ocpus
  postgresql_instance_flex_shape_memory = var.postgresql_instance_flex_shape_memory
  # OCPUs & memory for flex shape in hotstanby1 node (aarch64/OL8).
  postgresql_deploy_hotstandby1            = var.postgresql_deploy_hotstandby1
  postgresql_hotstandby1_shape             = var.postgresql_hotstandby1_shape
  postgresql_hotstandby1_flex_shape_ocpus  = var.postgresql_hotstandby1_flex_shape_ocpus
  postgresql_hotstandby1_flex_shape_memory = var.postgresql_hotstandby1_flex_shape_memory
  # OCPUs & memory for flex shape in hotstanby2 node (aarch64/OL8).
  postgresql_deploy_hotstandby2            = var.postgresql_deploy_hotstandby2
  postgresql_hotstandby2_shape             = var.postgresql_hotstandby2_shape
  postgresql_hotstandby2_flex_shape_ocpus  = var.postgresql_hotstandby2_flex_shape_ocpus
  postgresql_hotstandby2_flex_shape_memory = var.postgresql_hotstandby2_flex_shape_memory
}

output "generated_ssh_private_key" {
  value     = module.arch-postgresql.generated_ssh_private_key
  sensitive = true
}

output "postgresql_master_session_private_ip" {
  value = module.arch-postgresql.postgresql_master_session_private_ip
}

output "bastion_ssh_postgresql_master_session_metadata" {
  value = module.arch-postgresql.bastion_ssh_postgresql_master_session_metadata
}

# output "install_bits_rendered" {
#     value = module.arch-postgresql.install_bits
# }

# output "postgresql_hotstandby1_private_ip" {
#   value = module.arch-postgresql.postgresql_hotstandby1_private_ip
# }

# output "bastion_ssh_postgresql_hotstandby1_session_metadata" {
#   value = module.arch-postgresql.bastion_ssh_postgresql_hotstandby1_session_metadata
# }

# output "postgresql_hotstandby2_private_ip" {
#   value = module.arch-postgresql.postgresql_hotstandby2_private_ip
# }

# output "bastion_ssh_postgresql_hotstandby2_session_metadata" {
#   value = module.arch-postgresql.bastion_ssh_postgresql_hotstandby2_session_metadata
# }
