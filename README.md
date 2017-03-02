# Atlassian Bamboo Docker

## Run single container

Just run `docker run -it --name bamboo -p 8085:8085 kardasz/atlassian-bamboo` and open browser http://127.0.0.1:8085

## Use docker-compose (with PostgreSQL database and backup service)

Run `docker-compose up -d` and open browser http://127.0.0.1:8085 and use following settings `host: postgres`, `user: bamboo`, `password: bamboo`, `database: bamboo`.

### Env variables

- ``BAMBOO_BACKUP_VOLUME`` mount local dir or named volume (default named volume) for backup storage. For local dir user user:group `5000:5000`
- ``POSTGRES_PASSWORD`` database password
- ``BIND_IP`` ip address for attach services
- ``CRON_CLEANUP="0 0 * * *"`` cron scheduler for remove old backup files (older than 14 days). Empty string for disable.
- ``CRON_CRON_POSTGRES="15 0 * * *"`` cron scheduler for database dump. Empty string for disable.
- ``CRON_CRON_DATA="45 0 * * *"`` cron scheduler for backup bamboo data. Empty string for disable.


## Makefile commands:

- ``make ps`` display docker-compose processes
- ``make up`` start containers
- ``make stop`` stop containers
- ``make restart`` restart containers
- ``make down`` stop & remove containers
- ``make build`` build images
- ``make logs`` display real-time logs
- ``SERVICE=bamboo|postgres|backup EXEC_ARGS="command..." make exec`` execute command on selected container
- ``SERVICE=bamboo|postgres|backup make bash`` attach bash terminal on selected container
- ``make bamboo`` attach bash terminal on bamboo container
- ``make psql`` attach psql terminal

