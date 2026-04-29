FROM eclipse-temurin:11-jdk

# Base utilities + SSH (Hadoop pseudo-distributed setup)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      openssh-server \
      rsync \
      wget \
      vim \
      sudo && \
    rm -rf /var/lib/apt/lists/*

# SSH runtime dir
RUN mkdir -p /var/run/sshd
RUN mkdir -p /opt/hadoop-3.4.1/logs
# Hadoop
ADD hadoop-3.4.1.tar.gz /opt/
ENV HADOOP_HOME=/opt/hadoop-3.4.1
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
ENV PATH=${PATH}:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin

# Hadoop user
RUN useradd -m -s /bin/bash hadoop && \
    chown -R hadoop:hadoop /opt/hadoop-3.4.1 && \
    echo "hadoop ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# SSH key setup for hadoop user
RUN mkdir -p /home/hadoop/.ssh && \
    chown -R hadoop:hadoop /home/hadoop/.ssh && \
    chmod 700 /home/hadoop/.ssh && \
    sudo -u hadoop ssh-keygen -t rsa -N "" -f /home/hadoop/.ssh/id_rsa && \
    cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys && \
    chown hadoop:hadoop /home/hadoop/.ssh/authorized_keys && \
    chmod 600 /home/hadoop/.ssh/authorized_keys
# after HADOOP_HOME is set
COPY core-site.xml ${HADOOP_HOME}/etc/hadoop/core-site.xml
COPY hdfs-site.xml ${HADOOP_HOME}/etc/hadoop/hdfs-site.xml
COPY workers ${HADOOP_HOME}/etc/hadoop/workers
# optional but recommended: disable renice warning
RUN echo 'export HADOOP_NICENESS=' >> ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh

# ensure hadoop user owns configs
RUN chown hadoop:hadoop ${HADOOP_HOME}/etc/hadoop/core-site.xml \
    ${HADOOP_HOME}/etc/hadoop/hdfs-site.xml
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8020 22 9870 9000 8088 10020 19888
CMD ["/entrypoint.sh"]
