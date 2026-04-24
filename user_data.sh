#!/bin/bash

# Atualiza
yum update -y

# Instala Docker
yum install docker -y

# Inicia Docker
systemctl start docker
systemctl enable docker

# Permissão
usermod -aG docker ec2-user

# Login no ECR
aws ecr get-login-password --region us-east-2 | \
docker login --username AWS --password-stdin 142280718316.dkr.ecr.us-east-2.amazonaws.com

# Pull da imagem
docker pull 142280718316.dkr.ecr.us-east-2.amazonaws.com/pedrx12356:latest

# Rodar container
docker run -d -p 80:80 142280718316.dkr.ecr.us-east-2.amazonaws.com/pedrx12356:latest
