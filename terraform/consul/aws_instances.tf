resource "aws_instance" "consul" {
    count         = 1
    ami           = "${var.consul_ami}"
    key_name      = "${aws_key_pair.auth.id}"
    instance_type = "t2.nano"
    
    connection {
      user = "ubuntu"
    }
   
    security_groups = [ "${aws_security_group.docker.id}", "${aws_security_group.consul.id}" ]
    subnet_id = "${module.vpc.public_subnet_id}"
    
    tags {
        service = "consul"
        role    = "server"
        env     = "staging"
    }
}