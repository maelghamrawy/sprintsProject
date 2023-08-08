
resource "aws_eks_cluster" "eks" {
  name     = "EKS-Cluster-sp"
  role_arn = aws_iam_role.master-sp.arn

  vpc_config {
    subnet_ids = [aws_subnet.public_subnet1_eks-sp.id, aws_subnet.public_subnet2_eks-sp.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSServicePolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
  ]

}

resource "aws_iam_role" "master-sp" {
  name = "eks-master-sp"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.master-sp.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.master-sp.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.master-sp.name
}



resource "aws_iam_instance_profile" "worker-sp" {      
  depends_on = [aws_iam_role.worker]
  role       = aws_iam_role.worker.name
}

resource "aws_eks_node_group" "node-grp" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "node-sp"
  node_role_arn   = aws_iam_role.worker.arn
  subnet_ids      = [aws_subnet.public_subnet1_eks-sp.id, aws_subnet.public_subnet2_eks-sp.id]
  ami_type        = "AL2_x86_64"
  instance_types  = ["t2.medium"]

  remote_access {
    ec2_ssh_key = "Project"
  }


  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}


resource "aws_iam_role" "worker" {
  name = "ed-eks-worker"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "autoscaler" {
  name   = "eks-autoscaler-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeTags",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF

}



resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "autoscaler" {
  policy_arn = aws_iam_policy.autoscaler.arn
  role       = aws_iam_role.worker.name
}


resource "aws_subnet" "public_subnet1_eks-sp" {
  vpc_id            = aws_vpc.vpc-sp.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_subnet2_eks-sp" {
  vpc_id            = aws_vpc.vpc-sp.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
}


resource "aws_route_table" "rt-sp" {
  vpc_id = aws_vpc.vpc-sp.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-ec2-sp.id
  }

  tags = {
    Name = "Route Table1-eks"
  }
}
resource "aws_route_table_association" "rt_1" {
  subnet_id      = aws_subnet.public_subnet1_eks-sp.id
  route_table_id = aws_route_table.rt-sp.id
}

resource "aws_route_table" "rt-2" {
  vpc_id = aws_vpc.vpc-sp.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-ec2-sp.id
  }

  tags = {
    Name = "Route Table2-eks"
  }
}
resource "aws_route_table_association" "rt_2" {
  subnet_id      = aws_subnet.public_subnet2_eks-sp.id
  route_table_id = aws_route_table.rt-2.id
}