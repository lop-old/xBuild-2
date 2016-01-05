FROM poixson/centos:7.2.1511
MAINTAINER LorenzoP <lorenzo@poixson.com>

RUN yum update -y
RUN yum install -y shellscripts perl perl-xml

#COPY xbuild-setup.service /etc/systemd/system/xbuild-setup.service
ENTRYPOINT cat /etc/redhat-release

EXPOSE 80/tcp

