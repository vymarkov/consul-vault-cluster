resource "aws_route53_record" "vault_lb" {
   zone_id = "${var.route53_zone_id}"
   name = "vault.${var.domain}"
   type = "A"
   ttl = "300"
   records = ["${aws_instance.vault_lb.public_ip}"]
   
   depends_on = [ "aws_instance.vault_lb" ]
}

output vault_lb_addr {
  value = "${aws_route53_record.vault_lb.fqdn}"
} 