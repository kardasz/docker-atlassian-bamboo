FROM debian:jessie

MAINTAINER Krzysztof Kardasz <krzysztof@kardasz.eu>

# Update system and install required packages
ENV DEBIAN_FRONTEND noninteractive

# Install git, download and extract Stash and create the required directory layout.
# Try to limit the number of RUN instructions to minimise the number of layers that will need to be created.
RUN apt-get update -qq \
    && apt-get install -y wget curl git unzip libtcnative-1 xmlstarlet \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

# Download Oracle JDK
ENV ORACLE_JDK_VERSION jdk-8u121
ENV ORACLE_JDK_URL    http://download.oracle.com/otn-pub/java/jdk/8u121-b13/e9e7ea248e2c4826b92b3f075a80e441/jdk-8u121-linux-x64.tar.gz
RUN mkdir -p /opt/jdk/$ORACLE_JDK_VERSION && \
    wget --header "Cookie: oraclelicense=accept-securebackup-cookie" -O /opt/jdk/$ORACLE_JDK_VERSION/$ORACLE_JDK_VERSION.tar.gz $ORACLE_JDK_URL && \
    tar -zxf /opt/jdk/$ORACLE_JDK_VERSION/$ORACLE_JDK_VERSION.tar.gz --strip-components=1 -C /opt/jdk/$ORACLE_JDK_VERSION && \
    rm /opt/jdk/$ORACLE_JDK_VERSION/$ORACLE_JDK_VERSION.tar.gz && \
    update-alternatives --install /usr/bin/java java /opt/jdk/$ORACLE_JDK_VERSION/bin/java 100 && \
    update-alternatives --install /usr/bin/javac javac /opt/jdk/$ORACLE_JDK_VERSION/bin/javac 100

ENV DOWNLOAD_URL        https://www.atlassian.com/software/bamboo/downloads/binary/atlassian-bamboo-

ENV JAVA_HOME /opt/jdk/${ORACLE_JDK_VERSION}
ENV JAVA_TRUSTSTORE ${JAVA_HOME}/jre/lib/security/cacerts
ENV JAVA_TRUSTSTORE_PASSWORD changeit
ENV JAVA_OPTS "-Djavax.net.ssl.trustStore=${JAVA_TRUSTSTORE} -Djavax.net.ssl.trustStorePassword=${JAVA_TRUSTSTORE_PASSWORD}"

# Use the default unprivileged account. This could be considered bad practice
# on systems where multiple processes end up being executed by 'daemon' but
# here we only ever run one process anyway.
ENV RUN_USER            atlassian
ENV RUN_USER_UID        5000
ENV RUN_GROUP           atlassian
ENV RUN_GROUP_GID       5000

RUN \
    groupadd --gid ${RUN_GROUP_GID} -r ${RUN_GROUP} && \
    useradd -r --uid ${RUN_USER_UID} -g ${RUN_GROUP} ${RUN_USER}


ENV BAMBOO_HOME          /var/atlassian/bamboo/data
RUN \
    mkdir -p ${BAMBOO_HOME} && \
    chown -R ${RUN_USER}:${RUN_GROUP} ${BAMBOO_HOME}

ENV BAMBOO_INSTALL_DIR   /opt/atlassian/bamboo
ENV BAMBOO_VERSION 5.15.0.1

RUN mkdir -p                             ${BAMBOO_INSTALL_DIR} \
    && curl -L --silent                  ${DOWNLOAD_URL}${BAMBOO_VERSION}.tar.gz | tar -xz --strip=1 -C "$BAMBOO_INSTALL_DIR" \
    && mkdir -p                          ${BAMBOO_INSTALL_DIR}/conf/Catalina      \
    && chown -R root:root                ${BAMBOO_INSTALL_DIR}/                   \
    && chmod -R 755                      ${BAMBOO_INSTALL_DIR}/                   \
    && chmod -R 700                      ${BAMBOO_INSTALL_DIR}/conf/Catalina      \
    && chmod -R 700                      ${BAMBOO_INSTALL_DIR}/logs               \
    && chmod -R 700                      ${BAMBOO_INSTALL_DIR}/temp               \
    && chmod -R 700                      ${BAMBOO_INSTALL_DIR}/work               \
    && chown -R ${RUN_USER}:${RUN_GROUP} ${BAMBOO_INSTALL_DIR}/logs               \
    && chown -R ${RUN_USER}:${RUN_GROUP} ${BAMBOO_INSTALL_DIR}/temp               \
    && chown -R ${RUN_USER}:${RUN_GROUP} ${BAMBOO_INSTALL_DIR}/work               \
    && chown -R ${RUN_USER}:${RUN_GROUP} ${BAMBOO_INSTALL_DIR}/conf

# MySQL connector
ENV MYSQL_CONNECTOR_VERSION 5.1.40
RUN \
    wget -O ${BAMBOO_INSTALL_DIR}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.tar.gz http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.tar.gz && \
    tar xzf ${BAMBOO_INSTALL_DIR}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.tar.gz -C ${BAMBOO_INSTALL_DIR} && \
    mv ${BAMBOO_INSTALL_DIR}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}-bin.jar ${BAMBOO_INSTALL_DIR}/lib/ && \
    rm -rf ${BAMBOO_INSTALL_DIR}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.tar.gz ${BAMBOO_INSTALL_DIR}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}

USER ${RUN_USER}:${RUN_GROUP}

VOLUME ["${BAMBOO_INSTALL_DIR}"]

EXPOSE 8085

WORKDIR $BAMBOO_INSTALL_DIR

CMD ["./bin/start-bamboo.sh", "-fg"]
