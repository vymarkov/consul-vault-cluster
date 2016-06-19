variable consul_cluster_count { default = 3 }
variable vault_cluster_count { default = 3 }
variable env { default = "development" }
variable project_name { default = "phoenix" }

resource "null_resource" "cluster" {
  triggers {
    consul_cluster_count = "${var.consul_cluster_count}"
    vault_cluster_count = "${var.vault_cluster_count}"
  }
  
  provisioner "local-exec" {
    command = <<EOF
    docker-machine rm -f ${var.project_name}-consul-leader 2>/dev/null
    docker-machine create -d virtualbox --virtualbox-memory 512 --engine-label project_name=${var.project_name} --engine-label env=${var.env} --engine-label service=consul --engine-label role=leader ${var.project_name}-consul-leader
    
    count=$(( ${var.consul_cluster_count} - 1 ))
    
    for ((i = 1; i <= $count; i++)); do 
    docker-machine rm -f ${var.project_name}-consul-server-0$i 2>/dev/null;
    docker-machine create -d virtualbox --virtualbox-memory 512 --engine-label project_name=${var.project_name} --engine-label env=${var.env} --engine-label service=consul --engine-label role=follower ${var.project_name}-consul-server-0$i
    done;
    
    for ((i = 1; i <= ${var.vault_cluster_count}; i++)); do
    docker-machine rm -f ${var.project_name}-vault-server-0$i 2>/dev/null;
    docker-machine create -d virtualbox --virtualbox-memory 512 --engine-label project_name=${var.project_name} --engine-label env=${var.env} --engine-label service=vault --engine-label role=server ${var.project_name}-vault-server-0$i
    done;
    
    docker-machine rm -f ${var.project_name}-vault-lb 2>/dev/null;
    docker-machine create -d virtualbox --virtualbox-memory 512 --engine-label project_name=${var.project_name} --engine-label env=${var.env} --engine-label service=vault_lb  --engine-label role=lb ${var.project_name}-vault-lb
EOF
  }
}