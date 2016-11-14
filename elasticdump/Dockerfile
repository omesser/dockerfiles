# From original Spencer Herzberg's dockerfile [sherzberg/elasticdump]
# with the addition of version locking
FROM ubuntu:14.04

MAINTAINER Oded Messer, odedm@iguaz.io

RUN apt-get update -qq && apt-get install -y software-properties-common

RUN apt-add-repository ppa:chris-lea/node.js

RUN apt-get update -qq && apt-get install -y nodejs=0.10.37-1chl1~trusty1

RUN npm install -g elasticdump@2.4.2

ENTRYPOINT ["/usr/bin/elasticdump"]
