resource "aws_ecr_repository" "consul" {
  name = "consul"
}

resource "aws_ecr_repository" "vault" {
  name = "vault"
}

