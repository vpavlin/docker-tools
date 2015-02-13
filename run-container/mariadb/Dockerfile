FROM fedora
MAINTAINER Vaclav Pavlin <vpavlin@redhat.com>

RUN yum -y update; yum clean all
RUN yum -y install net-tools psmisc hostname mariadb-server mariadb; yum clean all

RUN systemctl enable mariadb.service

ADD ./config_mariadb.sh /config_mariadb.sh

RUN chmod 755 /config_mariadb.sh
RUN /config_mariadb.sh
VOLUME [ "/sys/fs/cgroup" ]

EXPOSE 3306

CMD [ "/usr/sbin/init" ]

