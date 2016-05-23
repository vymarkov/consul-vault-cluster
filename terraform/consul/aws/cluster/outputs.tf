output "consul_repository_url" {
  value = "${aws_ecr_repository.consul.repository_url}"
}

output "vault_repository_url" {
  value = "${aws_ecr_repository.vault.repository_url}"
}

output "consul_elb_address" {
  value = "http://${aws_elb.consul.dns_name}"
}

output "vault_elb_address" {
  value = "http://${aws_elb.vault.dns_name}"
}
