# ========== EKS Cluster ==========
resource "aws_eks_cluster" "dob_api" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids          = var.subnet_ids
    public_access_cidrs = var.cluster_public_access_cidrs # restrict API access (e.g. office IPs)
  }

  version = "1.26" # Keep updated to a supported version
}

# ========== IAM Role for EKS Cluster ==========
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "eks.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# ========== IAM Role for EKS Worker Nodes ==========
resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSCNIPolicy"
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# ========== Security Group for Node Group SSH Access ==========
resource "aws_security_group" "eks_ssh" {
  name        = "${var.cluster_name}-eks-ssh"
  description = "Allow SSH access to EKS worker nodes"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from office"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.office_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-eks-ssh"
  }
}

# ========== EKS Node Group ==========
resource "aws_eks_node_group" "dob_api_nodes" {
  cluster_name    = aws_eks_cluster.dob_api.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 2
  }

  instance_types = ["t3.medium"]

  remote_access {
    ec2_ssh_key               = var.ec2_ssh_key_name
    source_security_group_ids = [aws_security_group.eks_ssh.id]
  }

  ami_type = "AL2_x86_64"


  tags = {
    Environment = "production"
    Project     = "dob-api"
  }
}

# ========== EKS Addons ==========
resource "aws_eks_addon" "vpc_cni" {
  cluster_name      = aws_eks_cluster.dob_api.name
  addon_name        = "vpc-cni"
  addon_version     = "v1.14.1-eksbuild.1" # or latest supported
  resolve_conflicts = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  cluster_name  = aws_eks_cluster.dob_api.name
  addon_name    = "coredns"
  addon_version = "v1.10.1-eksbuild.2"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name  = aws_eks_cluster.dob_api.name
  addon_name    = "kube-proxy"
  addon_version = "v1.29.1-eksbuild.1" # Match with your EKS version
}