### Running a Consul + Vault Cluster using Docker  
=================================================

#### Pre-Requisite
----

- docker-machine ( Mac OS : brew install docker-machine )
- docker ( Mac OS :  brew install docker )
- direnv ( Mac OS : brew install direnv )

### Quick start guide 
----

#### Stack

- `consul-leader` consul server is a backend for Vault, leader in a Consul cluster,  should be started with bootstrap-except flag, should go into leader mode
- `consul-server` yet another Consul server, should be a member of Consul cluster and after joined to the cluster should go into standby mode 
- `vault-leader` vault server
- `vault-slave` yet another Vault server to demonstrate how works HA

#### Setup 
The following commands need to execute from a root of this repo/ 

Create a Docker host for development puposes, we will use VirtualBox driver

  $ docker-machine create --driver virtualbox consul-vault-cluster  
  
For direnv to work properly it needs to be hooked into the shell. Follow the direnv setup guide from
the direnv [repo] (https://github.com/direnv/direnv). Next run command below:

  $ direnv allow
  
Need to build a docker image for Consul.
```  
  $ ./build-consul-image.sh
```  
Run a Consul cluster: 
```
  $ docker-compose -f docker-compose/consul-cluster.dev.2.yml up -d
```  
Run a Vault cluster:
```
  $ docker-compose -f docker-compose/vault-cluster.dev.yml up -d
```  
Now a Consul + Vault cluster is readry for use. Try to connect the vault server using below command: 
```
  $ vault status
```  
For the first time you need to init the vault server:
```
  $ vault init 
```
When the vault server was initialised you need to unseal using given shared keys from command above:
```
  $ vault unseal <your_key_1>
  $ vault unseal <your_key_2>
  $ vault unseal <your_key_3>
```  
That's all, the server is initialised and unsealed now.

#### TODO
----

- Add support for additional providers like AWS
- Optimize the code to use the above data rather than being static
- Add Test Cases to run on the cluster
- Improve docs