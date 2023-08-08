resource "aws_ecr_repository" "ecr-sp" {
  name                 = "ecr-sp"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}


resource "aws_ecr_repository_policy" "aws_ecr_policy" {
  repository = aws_ecr_repository.ecr-sp.name
  policy = data.aws_iam_policy_document.ecr-policy-sp.json
}


data "aws_iam_policy_document" "ecr-policy-sp" {
  statement {
    sid    = "new policy"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:DeleteRepository",
      "ecr:BatchDeleteImage",
      "ecr:SetRepositoryPolicy",
      "ecr:DeleteRepositoryPolicy",
      "sts:AssumeRole",
    ]
  }
}
