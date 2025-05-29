output "cluster_name" {
  value = aws_eks_cluster.dob_api.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.dob_api.endpoint
}

output "cluster_ca_certificate" {
  value = aws_eks_cluster.dob_api.certificate_authority[0].data
}

output "node_group_role_arn" {
  value = aws_iam_role.eks_node_role.arn
}

output "ecr_repository_url" {
  value = aws_ecr_repository.dob_api_repo.repository_url
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.dob_api.name}"
}

output "nlb_dns_name" {
  value = aws_lb.nlb.dns_name
}

output "nlb_zone_id" {
  value = aws_lb.nlb.zone_id
}