### GENERAL
region      = "us-west-1" # TODO: update here
name_prefix = "ansh193-"  # TODO: update here

global_tags = {
  ManagedBy   = "terraform"
  Application = "Palo Alto Networks VM-Series NGFW"
  Owner       = "PS Team"
}

ssh_key_name = "ansh-key" # TODO: update here

### VPC
vpcs = {
  security_vpc = {
    name = "security-vpc"
    cidr = "10.100.0.0/16"
    security_groups = {
      vmseries_mgmt = {
        name = "vmseries_mgmt"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
          ssh = {
            description = "Permit SSH"
            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
        }
      }
    }
    subnets = {
      # Add placeholders for the new interface subnets
      "10.100.0.0/24" = { az = "us-west-1b", subnet_group = "mgmt" }
      "10.100.1.0/24" = { az = "us-west-1b", subnet_group = "untrust" } # Example: Index 1
      "10.100.2.0/24" = { az = "us-west-1b", subnet_group = "trust" }   # Example: Index 2
    }
    routes = {
      mgmt_default = {
        vpc              = "security_vpc"
        subnet_group     = "mgmt"
        to_cidr          = "0.0.0.0/0"
        destination_type = "ipv4"
        next_hop_key     = "security_vpc"
        next_hop_type    = "internet_gateway"
      }
    }
  }
}

### VM-SERIES
vmseries = {
  vmseries = {
    instances = {
      "01" = { az = "us-west-1b" }
    }

    bootstrap_options = {
      mgmt-interface-swap           = "disable"
      panorama-server               = "cloud"
      dgname                        = "All Firewalls"
      dhcp-send-hostname            = "yes"
      dhcp-send-client-id           = "yes"
      dhcp-accept-server-hostname   = "yes"
      dhcp-accept-server-domain     = "yes"
      plugin-op-commands            = "advance-routing:enable"
      vm-series-auto-registration-pin-id    = "59e46212-45ea-4ccc-a04e-d14d36327cf3"
      vm-series-auto-registration-pin-value = "221a3295794047cb9431935c6f2c9ba3"
    }

    airs_deployment = true
    panos_version   = "11.2.5-h1" # TODO: update here
    vmseries_ami_id = "ami-07fdc45c429e2e5e8"
    ebs_kms_id      = "alias/aws/ebs"

    vpc = "security_vpc"

    interfaces = {
      # 1. Management Interface (Device Index 0) - Source/Dest Check ENABLED
      mgmt = {
        device_index      = 0
        private_ip = {
          "01" = "10.100.0.4"
        }
        security_group    = "vmseries_mgmt"
        vpc               = "security_vpc"
        subnet_group      = "mgmt"
        create_public_ip  = true
        source_dest_check = true # Enabled for Mgmt interface
      }

      # 2. Data Interface 1 (Device Index 1) - Source/Dest Check DISABLED
      interface_eth1 = {
        device_index      = 1
        private_ip = {
          "01" = "10.100.1.4" # IP in the 'untrust' subnet
        }
        security_group    = "vmseries_data"  # Placeholder SG for data plane
        vpc               = "security_vpc"
        subnet_group      = "untrust"        # Subnet group for this interface
        create_public_ip  = false
        source_dest_check = false            # <-- CRITICAL: DISABLED for firewall data plane
      }

      # 3. Data Interface 2 (Device Index 2) - Source/Dest Check DISABLED
      interface_eth2 = {
        device_index      = 2
        private_ip = {
          "01" = "10.100.2.4" # IP in the 'trust' subnet
        }
        security_group    = "vmseries_data"  # Placeholder SG for data plane
        vpc               = "security_vpc"
        subnet_group      = "trust"          # Subnet group for this interface
        create_public_ip  = false
        source_dest_check = false            # <-- CRITICAL: DISABLED for firewall data plane
      }
    }
    system_services = {
      dns_primary = "4.2.2.2"
      ntp_primary = "pool.ntp.org"
    }
  }
}