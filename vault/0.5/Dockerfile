FROM golang:1.6-alpine
MAINTAINER Vitaly Markov <vymarkov@gmail.com>

ENV VAULT_VERSION 0.5.2
ENV VAULT_TMP /tmp/vault.zip
ENV VAULT_HOME /usr/local/bin
ENV PATH $PATH:${VAULT_HOME}
ENV PATH=$PATH:/usr/local/go/bin:/usr/local GOPATH=/usr/local/go

RUN apk --no-cache add git bash ca-certificates wget &&\
    wget --quiet --output-document=${VAULT_TMP} https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip &&\
    unzip ${VAULT_TMP} -d ${VAULT_HOME} &&\
    rm -f ${VAULT_TMP}
    
RUN mkdir -p $GOPATH/src/github.com/kelseyhightower &&\
  git clone --branch master https://github.com/kelseyhightower/confd.git $GOPATH/src/github.com/kelseyhightower/confd &&\
  cd $GOPATH/src/github.com/kelseyhightower/confd &&\
  git checkout b34d2236bfa3f062a7d8cdae8bc93b17fb340b96 &&\
  ./build &&\
  cp ./bin/confd /usr/local/confd

# Listener API tcp port
EXPOSE 8200

COPY ./confd /etc/confd/
COPY docker-entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["version"]
