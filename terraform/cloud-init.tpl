#cloud-config
package_update: true
package_upgrade: true
write_files:
  - path: /opt/app/docker-compose.yml
    permissions: "0644"
    content: |
      version: '3.9'
      services:
        app:
          image: ${APP_IMAGE_REPO}:${APP_TAG}
          container_name: node-app
          restart: unless-stopped
          env_file: [ ./.env ]
          ports:
            - "80:${APP_PORT}"
  - path: /opt/app/.env
    permissions: "0600"
    content: |
      APP_IMAGE_REPO=ghcr.io/your-org/your-repo
      APP_TAG=bootstrap
      APP_PORT=${app_port}
      DB_NAME=${db_name}
      DB_USER=${db_user}
      DB_PASSWORD=${db_pass}
      DB_HOST=${db_host}
  - path: /opt/app/healthcheck.sh
    permissions: "0755"
    content: |
      #!/usr/bin/env bash
      set -e
      curl -fsS http://localhost:${app_port}/health || exit 1
runcmd:
  - [ bash, -lc, "curl -fsSL https://get.docker.com | sh" ]
  - [ bash, -lc, "systemctl enable --now docker" ]
  - [ bash, -lc, "docker --version" ]
  - [ bash, -lc, "mkdir -p /opt/app" ]
  - [ bash, -lc, "cd /opt/app && echo 'Compose written. Use GH Action to start/update app image.' " ]
  - [ bash, -lc, "systemctl stop firewalld || true; systemctl disable firewalld || true" ]
