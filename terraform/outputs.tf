output "public_ip" { value = oci_core_instance.app.public_ip }
output "app_url"  { value = "http://${oci_core_instance.app.public_ip}/health" }
output "db_host" { value = oci_mysql_mysql_db_system.db.endpoints[0].ip_address }
output "db_port" { value = oci_mysql_mysql_db_system.db.endpoints[0].port }
output "db_user" { value = var.mysql_admin_username }
output "db_name" { value = var.db_name }
