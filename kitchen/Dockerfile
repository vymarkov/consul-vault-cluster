# Using the Dockerfile 
# 
#   You have an able to provison an infrastructure using this Dockerfile without 
#   need to install all the necessary tools such Terraform, Consul, Vault, aws-cli, jq, etc to your 
#   local workstation.
#
#   For the first you need to build a docker image from the Dockerfile. Firstly, install 
#   Docker and Docker Compose on your local machine if needed and run the command below:   
#     
#      $ docker-compose build
#   
#   Now we can run a container from our image to provison our cluster or interact with a your cluster:
#     
#      $ docker-compose run --rm kitchen zsh
#

FROM golang:1.6-wheezy
MAINTAINER Vitaly Markov <vymarkov@gmail.com>

ENV DOCKER_VERSION=1.11.1
ENV DOCKER_COMPOSE_VERSION=1.7.1
ENV DOCKER_MACHINE_VERSION=0.7.0
ENV TERRAFORM_VERSION=0.6.16
ENV CONSUL_VERSION=0.6.4
ENV VAULT_VERSION=0.5.2
ENV MONGO_VERSION=3.0.12
ENV REDIS_VERSION=3.2.0
ENV JQ_VERSION=1.5
ENV TERM=xterm

RUN apt-get update &&\
  apt-get install git zsh httpie python-pip less unzip -y
  
RUN pip install --upgrade httpie awscli
  
RUN curl -L https://github.com/stedolan/jq/releases/download/jq-$JQ_VERSION/jq-linux64 > /usr/local/bin/jq &&\
  chmod +x /usr/local/bin/jq

RUN git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh &&\
  cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc &&\
  chsh -s /bin/zsh

# Installing a Docker Version Manager and Docker
RUN curl -sL https://download.getcarina.com/dvm/latest/install.sh | sh &&\
  echo 'source $HOME/.dvm/dvm.sh' >> ~/.zshrc &&\
  zsh -c "source $HOME/.dvm/dvm.sh && dvm install $DOCKER_VERSION" &&\
  echo 'dvm use $DOCKER_VERSION' >> ~/.zshrc
  
# Installing the Docker Compose 
RUN curl -L https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose &&\
  chmod +x /usr/local/bin/docker-compose
  
# Installing the Docker Machine
RUN curl -L https://github.com/docker/machine/releases/download/v$DOCKER_MACHINE_VERSION/docker-machine-`uname -s`-`uname -m` >/usr/local/bin/docker-machine &&\
  chmod +x /usr/local/bin/docker-machine

RUN git clone -b master https://github.com/direnv/direnv &&\
  cd direnv &&\
  git checkout ab99ac551bd95e1c2c611e6af1f8a4d625497c42 &&\
  make install &&\
  echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc &&\
  rm -rf direnv 

# Terraform 
RUN curl -OL https://releases.hashicorp.com/terraform/$TERRAFORM_VERSION/terraform_"$TERRAFORM_VERSION"_linux_amd64.zip &&\
  unzip terraform_"$TERRAFORM_VERSION"_linux_amd64.zip -d /usr/local/bin/

# Consul
RUN curl -OL https://releases.hashicorp.com/consul/$CONSUL_VERSION/consul_"$CONSUL_VERSION"_linux_amd64.zip &&\
  unzip consul_"$CONSUL_VERSION"_linux_amd64.zip &&\
  mv consul /usr/local/bin/consul

# Vault
RUN curl -OL https://releases.hashicorp.com/vault/$VAULT_VERSION/vault_"$VAULT_VERSION"_linux_amd64.zip &&\
  unzip vault_"$VAULT_VERSION"_linux_amd64.zip &&\
  mv vault /usr/local/bin/vault &&\
  # Mongotools  
  curl -OL https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-debian71-${MONGO_VERSION}.tgz &&\
  tar -xvf mongodb-linux-x86_64-debian71-${MONGO_VERSION}.tgz &&\
  cd mongodb-linux-x86_64-debian71-${MONGO_VERSION}/bin &&\
  mv bsondump mongo mongodump mongoexport mongofiles mongoimport mongooplog mongoperf mongorestore mongostat mongotop /usr/local/bin/

RUN wget http://download.redis.io/releases/redis-${REDIS_VERSION}.tar.gz &&\
  tar -xvf redis-${REDIS_VERSION}.tar.gz && cd redis-${REDIS_VERSION} && make &&\
  cp src/redis-cli /usr/local/bin/
  
RUN wget https://dl.eff.org/certbot-auto &&\
  chmod a+x ./certbot-auto && mv certbot-auto /usr/local/bin 
  
RUN mkdir /usr/kitchen
WORKDIR /usr/kitchen

CMD zsh