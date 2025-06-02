output "primary_private_ip" {
  value = aws_instance.db_primary.private_ip
}

output "replica_private_ip" {
  value = aws_instance.db_replica.private_ip
}

output "db_replica_instance_id" {
  value = aws_instance.db_replica.id
}

output "ec2_private_key_pem" {
  value     = tls_private_key.ec2_key.private_key_pem
  sensitive = true
}

output "private_key_pem" {
  value     = tls_private_key.ec2_key.private_key_pem
  sensitive = true
}

