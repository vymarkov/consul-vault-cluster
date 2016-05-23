FROM golang:1.6-wheezy
MAINTAINER Vitaly Markov <vymarkov@gmail.com>

ENV TERM=xterm
ENV DOCKER_VERSION=1.11.1
ENV DOCKER_COMPOSE_VERSION=1.7.1
ENV DOCKER_MACHINE_VERSION=0.7.0
ENV TERRAFORM_VERSION=0.6.16
ENV CONSUL_VERSION=0.6.4
ENV VAULT_VERSION=0.5.2
ENV JQ_VERSION=1.5

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
  mv vault /usr/local/bin/vault

RUN mkdir /usr/kitchen
WORKDIR /usr/kitchen

CMD zsh