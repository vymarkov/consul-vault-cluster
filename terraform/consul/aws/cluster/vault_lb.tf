resource "aws_elb" "vault" {
  name                        = "vault"
  connection_draining         = true
  connection_draining_timeout = 400
  security_groups             = ["${aws_security_group.vault_elb.id}"]
  instances                   = ["${aws_instance.consul.*.id}"]
  availability_zones          = ["us-east-1a", "us-east-1c", "us-east-1d", "us-east-1e"]
  cross_zone_load_balancing   = true

  listener {
    instance_port     = 8200
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    target              = "${var.vault_elb_health_check}"
    interval            = 15
  }

  tags {
    Name = "Vault ELB"
  }
}
