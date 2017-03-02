#!/bin/bash
set -e

if [ "$1" = '/usr/bin/supervisord' ]; then

    # Task cleanup (remove old backups > 14 days)
    echo "find ${BAMBOO_BACKUP} -type f -mtime +14 -exec rm -f {} \;" > /cronjob_bamboo.cleanup.sh
    chmod +x /cronjob_bamboo.cleanup.sh

    # Task backup postgress
    echo "PGPASSWORD=${PGPASSWORD} pg_dump -h postgres -U bamboo | gzip > ${BAMBOO_BACKUP}/bamboo.postgres.\`date +%Y-%m-%d-%H-%M-%S\`.gz" > /cronjob_bamboo.postgres.sh
    chmod +x /cronjob_bamboo.postgres.sh

    # Task backup data
    echo "tar --exclude='data/xml-data/build-dir' -cf ${BAMBOO_BACKUP}/bamboo.data.\`date +%Y-%m-%d-%H-%M-%S\`.tar -C `dirname ${BAMBOO_HOME}` `basename ${BAMBOO_HOME}`" > /cronjob_bamboo.data.sh
    chmod +x /cronjob_bamboo.data.sh

    # Create crontab file
    echo '' > /etc/crontab

    # ENV
    echo 'SHELL=/bin/bash' >> /etc/crontab
    echo 'PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin' >> /etc/crontab

    if [ "${CRON_CLEANUP}" != "" ]; then
        echo "${CRON_CLEANUP} atlassian bash /cronjob_bamboo.cleanup.sh 2>&1" >> /etc/crontab
    fi

    if [ "${CRON_POSTGRES}" != "" ]; then
        echo "${CRON_POSTGRES} atlassian bash /cronjob_bamboo.postgres.sh 2>&1" >> /etc/crontab
    fi

    if [ "${CRON_DATA}" != "" ]; then
        echo "${CRON_DATA} atlassian bash /cronjob_bamboo.data.sh 2>&1" >> /etc/crontab
    fi

    # Blank line
    echo '' >> /etc/crontab
fi

exec "$@"
