FROM postgres:9.6

MAINTAINER Krzysztof Kardasz <krzysztof@kardasz.eu>

ENV DEBIAN_FRONTEND noninteractive

ARG RUN_USER
ENV RUN_USER ${RUN_USER:-atlassian}

ARG RUN_USER_UID
ENV RUN_USER_UID ${RUN_USER_UID:-5000}

ARG RUN_GROUP
ENV RUN_GROUP ${RUN_GROUP:-atlassian}

ARG RUN_GROUP_GID
ENV RUN_GROUP_GID ${RUN_GROUP_GID:-5000}

ARG CRON_CLEANUP
ENV CRON_CLEANUP ${CRON_CLEANUP:-"0 0 * * *"}

ARG CRON_POSTGRES
ENV CRON_POSTGRES ${CRON_POSTGRES:-"15 0 * * *"}

ARG CRON_DATA
ENV CRON_DATA ${CRON_DATA:-"45 0 * * *"}

# Try to limit the number of RUN instructions to minimise the number of layers that will need to be created.
RUN apt-get update -qq \
    && apt-get install -y wget curl rsync syslog-ng supervisor cron \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/ \
    && rm -f /etc/{cron.d,cron.daily,cron.hourly,cron.monthly,cron.weekly}/*

RUN groupadd --gid ${RUN_GROUP_GID} -r ${RUN_GROUP} && \
    useradd -r --uid ${RUN_USER_UID} -g ${RUN_GROUP} -s /bin/bash ${RUN_USER} && \
    mkdir -p ${BAMBOO_BACKUP} && \
    chown -R ${RUN_USER}:${RUN_GROUP} ${BAMBOO_BACKUP}

ADD supervisord.conf /etc/

VOLUME ${BAMBOO_BACKUP}
WORKDIR ${BAMBOO_BACKUP}

COPY docker-entrypoint.sh /entrypoint.sh

RUN chmod a+x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]