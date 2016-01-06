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

RUN echo 'daemon off;' >> /etc/nginx/nginx.conf
COPY ./src/etc/supervisord.conf        /etc/supervisord.conf
COPY ./src/etc/supervisord.d/nginx.ini   /etc/supervisord.d/nginx.ini
COPY ./src/etc/supervisord.d/php-fpm.ini /etc/supervisord.d/php-fpm.ini

EXPOSE 80/tcp
ENTRYPOINT /usr/bin/supervisord -c /etc/supervisord.conf
