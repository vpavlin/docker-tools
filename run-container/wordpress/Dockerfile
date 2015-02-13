FROM fedora
MAINTAINER Vaclav Pavlin <vpavlin@redhat.com>

RUN yum -y install httpd php php-common php-mysql tar patch; yum clean all

RUN systemctl enable httpd.service

RUN curl -O https://wordpress.org/latest.tar.gz

RUN tar -xvzf latest.tar.gz -C /var/www/html

ADD wordpress.conf /etc/httpd/conf.d/wordpress.conf
ADD config.patch /

WORKDIR /var/www/html/wordpress

RUN cp wp-config-sample.php wp-config.php; patch wp-config.php < /config.patch

VOLUME [ "/sys/fs/cgroup" ]

EXPOSE 80

CMD /usr/sbin/init

