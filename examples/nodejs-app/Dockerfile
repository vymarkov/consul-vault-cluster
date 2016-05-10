FROM node:5.10
MAINTAINER Vitaly Markov "v.y.markov@gmail.com"

ENV PATH=$PATH:/usr/local/go/bin:/usr/local GOPATH=/usr/local/go

RUN apt-get update &&\
	apt-get install python-pip -y &&\
	pip install httpie

RUN mkdir /tmp/golang &&\
  cd /tmp/golang &&\
  wget https://storage.googleapis.com/golang/go1.6.2.linux-amd64.tar.gz &&\
  tar -C /usr/local -xzf go1.6.2.linux-amd64.tar.gz

RUN mkdir -p $GOPATH/src/github.com/kelseyhightower &&\
  git clone --branch master https://github.com/kelseyhightower/confd.git $GOPATH/src/github.com/kelseyhightower/confd &&\
  cd $GOPATH/src/github.com/kelseyhightower/confd &&\
  git checkout b34d2236bfa3f062a7d8cdae8bc93b17fb340b96 &&\
  ./build &&\
  cp ./bin/confd /usr/local/confd

RUN mkdir -p /usr/src/app
  
WORKDIR /usr/src/app

COPY package.json /usr/src/app/
RUN npm install

COPY ./confd /etc/confd/
COPY . /usr/src/app

STOPSIGNAL SIGINT
CMD npm start