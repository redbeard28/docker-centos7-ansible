FROM centos/systemd
MAINTAINER "Jeremie CUADRADO" <jeremie_cuadrado@carrefour.com>
#
ENV BR2_TARGET_GENERIC_GETTY_PORT "tty1"
ARG LC_ALL=en_US.UTF-8
#
RUN echo "LC_ALL=en_US.utf8" > /etc/environment
RUN source /etc/environment
RUN yum -y update; yum clean all
RUN yum -y install https://centos7.iuscommunity.org/ius-release.rpm
RUN yum -y install build-essential openssh-server openssh-clients deltarpm passwd sudo vi logrotate
RUN yum -y groupinstall "Development Tools"; yum clean all
#
# Disable requiretty.
RUN sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/'  /etc/sudoers
#
# ADD user ansible source: percygrunwald/docker-centos7-ansible
ENV ANSIBLE_USER=ansible SUDO_GROUP=wheel
RUN set -xe \
  && groupadd -r ${ANSIBLE_USER} \
  && useradd -m -g ${ANSIBLE_USER} ${ANSIBLE_USER} \
  && usermod -aG ${SUDO_GROUP} ${ANSIBLE_USER} \
  && sed -i "/^%${SUDO_GROUP}/s/ALL\$/NOPASSWD:ALL/g" /etc/sudoers
#
ADD ./run.sh /run.sh
RUN yum -y install python36 python36-pip; \
yum -y install gcc gcc-c++ make python36-devel openssl-devel libffi-devel; \
python3.6 -m pip install --upgrade pip; \
python3.6 -m pip install molecule;
#
RUN mkdir /data
RUN mkdir /var/run/sshd
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
RUN ln -s /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@ttyS0.service
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config && sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config
RUN systemctl enable sshd.service
RUN chmod 755 /run.sh
VOLUME [ "/sys/fs/cgroup" ]
EXPOSE 22
ENTRYPOINT ["/run.sh"]