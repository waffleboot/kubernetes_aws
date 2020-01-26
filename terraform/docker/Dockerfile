FROM ubuntu

ARG VER=0.12.20

WORKDIR /tmp/terraform

COPY hashicorp.asc .

RUN apt update && apt install -y gpg curl unzip && gpg --import hashicorp.asc

RUN curl -Os https://releases.hashicorp.com/terraform/${VER}/terraform_${VER}_SHA256SUMS           ;\
    curl -Os https://releases.hashicorp.com/terraform/${VER}/terraform_${VER}_SHA256SUMS.sig       ;\
    curl -Os https://releases.hashicorp.com/terraform/${VER}/terraform_${VER}_linux_amd64.zip      ;\
    gpg --verify terraform_${VER}_SHA256SUMS.sig terraform_${VER}_SHA256SUMS                       ;\
    sha256sum --check --quiet --ignore-missing terraform_${VER}_SHA256SUMS                         ;\
    unzip terraform_${VER}_linux_amd64.zip -d /usr/local/bin/ && rm -r /tmp/terraform

WORKDIR /
