terraform {
  required_version = ">= 1.5.0"
  required_providers {
    oci = { source = "oracle/oci", version = ">= 7.0.0" }
  }
}
provider "oci" { region = var.region }
data "oci_identity_availability_domains" "ads" { compartment_id = var.compartment_ocid }

resource "oci_core_vcn" "vcn" { cidr_block = var.vcn_cidr compartment_id = var.compartment_ocid display_name = "free-vcn" }
resource "oci_core_internet_gateway" "igw" { compartment_id = var.compartment_ocid display_name = "free-igw" vcn_id = oci_core_vcn.vcn.id enabled = true }
resource "oci_core_route_table" "rt" { compartment_id = var.compartment_ocid vcn_id = oci_core_vcn.vcn.id route_rules { network_entity_id = oci_core_internet_gateway.igw.id destination = "0.0.0.0/0" destination_type = "CIDR_BLOCK" } }
resource "oci_core_security_list" "sl" {
  compartment_id = var.compartment_ocid vcn_id = oci_core_vcn.vcn.id display_name = "free-sl"
  egress_security_rules { destination = "0.0.0.0/0" destination_type = "CIDR_BLOCK" protocol = "all" }
  ingress_security_rules { protocol = "6" source = var.ssh_cidr tcp_options { min = 22, max = 22 } }
  ingress_security_rules { protocol = "6" source = "0.0.0.0/0" tcp_options { min = 80, max = 80 } }
  ingress_security_rules { protocol = "6" source = var.public_subnet_cidr tcp_options { min = 3306, max = 3306 } }
}
resource "oci_core_subnet" "subnet" { cidr_block = var.public_subnet_cidr compartment_id = var.compartment_ocid vcn_id = oci_core_vcn.vcn.id route_table_id = oci_core_route_table.rt.id security_list_ids=[oci_core_security_list.sl.id] display_name="free-public" prohibit_public_ip_on_vnic = false }

resource "oci_mysql_mysql_db_system" "db" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id = var.compartment_ocid
  subnet_id = oci_core_subnet.subnet.id
  display_name = "free-mysql"
  shape_name = "MySQL.Free"
  admin_username = var.mysql_admin_username
  admin_password = var.mysql_admin_password
  database_name  = var.db_name
}

data "oci_core_images" "ol" {
  compartment_id = var.compartment_ocid
  operating_system = "Oracle Linux"
  sort_by = "TIMECREATED"
  sort_order = "DESC"
  shape = var.instance_shape
}
resource "oci_core_instance" "app" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id = var.compartment_ocid
  display_name = "free-node-app"
  shape = var.instance_shape
  dynamic "shape_config" { for_each = var.instance_shape == "VM.Standard.A1.Flex" ? [1] : [] content { ocpus = var.instance_ocpus memory_in_gbs = var.instance_memory_gbs } }
  source_details { source_type = "image" image_id = data.oci_core_images.ol.images[0].id }
  create_vnic_details { subnet_id = oci_core_subnet.subnet.id assign_public_ip = true }
  metadata = { ssh_authorized_keys = var.ssh_public_key user_data = base64encode(templatefile("${path.module}/cloud-init.tpl", { app_port=var.app_port, db_name=var.db_name, db_user=var.mysql_admin_username, db_pass=var.mysql_admin_password, db_host=oci_mysql_mysql_db_system.db.endpoints[0].ip_address })) }
  depends_on = [oci_mysql_mysql_db_system.db]
}
