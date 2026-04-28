FROM eclipse-temurin:11-jdk

RUN apt-get update && apt-get install -y ssh rsync wget vim sudo openjdk-11-jdk && rm -rf /var/lib/apt/lists/*

ADD hadoop-3.4.1.tar.gz /opt/
ENV HADOOP_HOME=/opt/hadoop-3.4.1
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
ENV PATH=$PATH:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin

RUN useradd -m -s /bin/bash hadoop \
 && chown -R hadoop:hadoop /opt/hadoop-3.4.1 \
 && echo "hadoop ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER hadoop
RUN ssh-keygen -t rsa -P "" -f /home/hadoop/.ssh/id_rsa \
 && cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys \
 && chmod 600 /home/hadoop/.ssh/authorized_keys

COPY --chown=hadoop:hadoop entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22 9870 9000 8088 10020 19888
CMD ["/entrypoint.sh"]
