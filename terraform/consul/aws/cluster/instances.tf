resource "aws_instance" "consul" {
  count                       = "${var.consul_cluster_size}"
  ami                         = "${var.consul_ami}"
  key_name                    = "${aws_key_pair.auth.id}"
  instance_type               = "t2.nano"
  associate_public_ip_address = true

  connection {
    user = "ubuntu"
  }

  #subnet_id = "${module.vpc.public_subnet_id}" 
  vpc_security_group_ids = ["${aws_security_group.docker.id}", "${aws_security_group.consul.id}", "${aws_security_group.vault.id}"]

  tags {
    Name = "${format("consul-server-%02d", count.index + 1)}"
    role = "server"
    env  = "staging"
  }
}
