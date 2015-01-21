FROM fedora
MAINTAINER Vaclav Pavlin <vpavlin@redhat.com>

RUN yum -y update; yum clean all
RUN yum -y install net-tools psmisc hostname mariadb-server mariadb; yum clean all

RUN systemctl enable mariadb.service

#We don't really care...
RUN systemctl mask systemd-remount-fs.service dev-hugepages.mount sys-fs-fuse-connections.mount systemd-logind.service getty.target console-getty.service
RUN cp /usr/lib/systemd/system/dbus.service /etc/systemd/system/; sed -i 's/OOMScoreAdjust=-900//' /etc/systemd/system/dbus.service

ADD ./config_mariadb.sh /config_mariadb.sh

RUN chmod 755 /config_mariadb.sh
RUN /config_mariadb.sh
VOLUME [ "/sys/fs/cgroup", "/run", "/tmp" ]

ENV container docker

EXPOSE 3306

CMD [ "/usr/sbin/init" ]

