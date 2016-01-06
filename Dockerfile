FROM centos:7
MAINTAINER LorenzoP <lorenzo@poixson.com>

RUN yum update -y
# RUN yum groupinstall -y Development\ Tools --setopt=group_package_types=mandatory,default,optional
RUN yum install -y http://yum.poixson.com/latest.rpm
RUN yum install -y epel-release webtatic-release
RUN yum install -y perl perl-xml
RUN yum install -y git subversion
RUN yum install -y shellscripts
RUN yum install -y supervisor
RUN yum install -y nginx18
RUN yum install -y php56w php56w-cli php56w-fpm php56w-xml php56w-gd
RUN yum clean all

#COPY xbuild-setup.service /etc/systemd/system/xbuild-setup.service
ENTRYPOINT cat /etc/redhat-release

EXPOSE 80/tcp

