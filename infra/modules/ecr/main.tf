resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        # Pipeline build images look like "<commit>-<build number>": keep the newest N.
        # Release tags such as 0.1.2 contain no hyphen, so this rule never touches them.
        rulePriority = 1
        description  = "Keep only the last ${var.keep_last} build images"
        selection = {
          tagStatus      = "tagged"
          tagPatternList = ["*-*"]
          countType      = "imageCountMoreThan"
          countNumber    = var.keep_last
        }
        action = { type = "expire" }
      },
      {
        # Failed or abandoned uploads leave untagged images behind
        rulePriority = 2
        description  = "Expire untagged images after 14 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 14
        }
        action = { type = "expire" }
      }
    ]
  })
}
