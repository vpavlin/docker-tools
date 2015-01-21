FROM fedora
MAINTAINER Vaclav Pavlin <vpavlin@redhat.com>

RUN yum -y install httpd php php-common php-mysql tar patch; yum clean all

RUN systemctl enable httpd.service

#We don't really care...
RUN systemctl mask systemd-remount-fs.service dev-hugepages.mount sys-fs-fuse-connections.mount systemd-logind.service getty.target console-getty.service
RUN cp /usr/lib/systemd/system/dbus.service /etc/systemd/system/; sed -i 's/OOMScoreAdjust=-900//' /etc/systemd/system/dbus.service

RUN curl -O https://wordpress.org/latest.tar.gz

RUN tar -xvzf latest.tar.gz -C /var/www/html

ADD wordpress.conf /etc/httpd/conf.d/wordpress.conf
ADD config.patch /

WORKDIR /var/www/html/wordpress

RUN cp wp-config-sample.php wp-config.php; patch wp-config.php < /config.patch

VOLUME [ "/sys/fs/cgroup", "/run", "/tmp" ]

ENV container docker
EXPOSE 80

CMD /usr/sbin/init

