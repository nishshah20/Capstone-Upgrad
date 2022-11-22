# --------------------------------------------------------
# vpc and subnets
# --------------------------------------------------------

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.prefix}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${local.region}a", "${local.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "nish-c5-project"
  }
}

module "self_ip_address" {
  source = "./modules/self_ip"
}

# --------------------------------------------------------
# IAM Role for ECR
# --------------------------------------------------------
resource "aws_iam_role" "role" {
  name               = "${var.prefix}-ecr-role"
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": ["ec2.amazonaws.com"]
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF

  tags = {
    Terraform = "true"
  }
}

resource "aws_iam_policy" "policy" {
  name = "${var.prefix}-ecr-access-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "attach" {
  name       = "${var.prefix}-attach"
  roles      = ["${aws_iam_role.role.name}"]
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_iam_instance_profile" "profile" {
  name = "${var.prefix}-instance-profile"
  role = aws_iam_role.role.name
}

# --------------------------------------------------------
# ECR Repository
# --------------------------------------------------------
resource "aws_ecr_repository" "ecr-node-repo" {
  name                 = "${var.prefix}-node-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name      = "${var.prefix}-node-repo"
    Terraform = "true"
  }
}