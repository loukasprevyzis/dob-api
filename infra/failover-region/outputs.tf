output "ec2_private_key_pem" {
  value     = module.db.ec2_private_key_pem
  sensitive = true
}