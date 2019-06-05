FROM centos:7
MAINTAINER "Jeremie CUADRADO" <jeremie_cuadrado@carrefour.com>
#
ENV BR2_TARGET_GENERIC_GETTY_PORT "tty1"
ENV LC_ALL en_US.UTF-8
#
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;
#
# deltarpm => https://www.certdepot.net/rhel7-get-started-delta-rpms/
# http_caching=packages => https://www.centos.org/forums/viewtopic.php?t=53278
#
RUN echo "LC_ALL=en_US.utf8" > /etc/environment
RUN source /etc/environment
RUN yum -y update; yum clean all
RUN yum -y install https://centos7.iuscommunity.org/ius-release.rpm
RUN yum -y install build-essential deltarpm passwd sudo wget vim logrotate
RUN yum -y groupinstall "Development Tools"; yum clean all
#
# Disable requiretty.
RUN sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/'  /etc/sudoers
#
# ADD user ansible original source: percygrunwald/docker-centos7-ansible
#
ENV ANSIBLE_USER=ansible SUDO_GROUP=wheel
RUN set -xe \
  && groupadd -r ${ANSIBLE_USER} \
  && useradd -m -g ${ANSIBLE_USER} ${ANSIBLE_USER} \
  && usermod -aG ${SUDO_GROUP} ${ANSIBLE_USER} \
  && sed -i "/^%${SUDO_GROUP}/s/ALL\$/NOPASSWD:ALL/g" /etc/sudoers
#
RUN yum -y install python36 python36-pip; \
yum -y install gcc gcc-c++ make python36-devel openssl-devel libffi-devel; \
python3.6 -m pip install --upgrade pip; \
python3.6 -m pip install molecule;
#
RUN ln -s /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@ttyS0.service
VOLUME [ "/sys/fs/cgroup" ]
EXPOSE 22
CMD ["/usr/lib/systemd/systemd"]