FROM eclipse-temurin:11-jdk
RUN apt-get update && apt-get install -y ssh rsync wget vim
ADD hadoop-3.4.1.tar.gz /opt/
ENV HADOOP_HOME=/opt/hadoop-3.4.1
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
ENV PATH=$PATH:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin
RUN ssh-keygen -t rsa -P "" -f /root/.ssh/id_rsa && cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys
COPY entrypoint.sh /entrypoint.sh
EXPOSE 22 9870 9000 50070 8088 10020 19888 50075
RUN chmod +x /entrypoint.sh
CMD ["/entrypoint.sh"]
