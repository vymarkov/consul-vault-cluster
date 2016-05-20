resource "aws_key_pair" "auth" {
  key_name   = "consul"
  public_key = "${file(var.consul_public_key_path)}"
}