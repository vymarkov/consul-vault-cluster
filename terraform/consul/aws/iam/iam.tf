resource "aws_iam_policy" "AmazonEC2Consul" {
    name   = "AmazonEC2Consul"
    description = "The policy describes which permissions has a role for creating resources for cluster"
    policy = "${file("${path.module}/policy/AmazonEC2Consul.json")}" 
}

resource "aws_iam_group" "consul" {
    name = "devops"
}

resource "aws_iam_user" "consul" {
    name = "consul"
    path = "/"
}

resource "aws_iam_group_membership" "consul" {
    name = "consul-group-membership"
    users = [
        "${aws_iam_user.consul.name}"
    ]
    group = "${aws_iam_group.consul.name}"
}

resource "aws_iam_access_key" "consul" {
    user = "${aws_iam_user.consul.name}"
}

resource "aws_iam_policy_attachment" "consul" {
    name = "consul"
    users = [ "${aws_iam_user.consul.name}" ]
    groups = [ "${aws_iam_group.consul.name}" ]
    policy_arn = "${aws_iam_policy.AmazonEC2Consul.arn}"
}

output "consul_access_key_id" {
  value = "${aws_iam_access_key.consul.id}"
}

output "consul_secret_access_key" {
  value = "${aws_iam_access_key.consul.secret}"
}