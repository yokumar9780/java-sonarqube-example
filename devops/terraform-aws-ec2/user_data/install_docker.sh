#!/bin/bash
# Update the system and install prerequisites
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common ec2-instance-connect
sudo apt-get install -y openjdk-21-jdk wget git
# Install Docker if it's not already installed
if ! command -v docker &>/dev/null; then
  sudo apt-get install -y docker.io
  sudo systemctl enable docker
  sudo systemctl start docker
  sudo usermod -aG docker ubuntu
  sudo usermod -aG docker ec2-user
fi

# Install docker-compose
curl -L https://github.com/docker/compose/releases/download/v2.30.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

apt-cache search docker | grep compose
sudo apt install docker-compose-v2

apt install unzip

# Install AWS SSM Agent
sudo snap install amazon-ssm-agent --classic
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 339712736991.dkr.ecr.eu-west-1.amazonaws.com

# Add user to docker group
sudo usermod -aG docker $USER

# Create directories for SonarQube and PostgreSQL
mkdir -p /opt/sonarqube && cd /opt/sonarqube

# Create a docker-compose.yml file for SonarQube and PostgreSQL
cat > docker-compose.yml <<EOL
services:
  traefik:
    image: "traefik:v3.2"
    container_name: "traefik"
    command:
      - "--log.level=DEBUG"
      - "--api.insecure=false"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80" # HTTP entry point
      - "--entrypoints.dashboard.address=:8089"  # Dashboard entry point
      - "--entryPoints.websecure.address=:443"
      - "--certificatesresolvers.myresolver.acme.tlschallenge=true"
      - "--certificatesresolvers.myresolver.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory"
      #- "--certificatesresolvers.myresolver.acme.caserver=https://acme-v02.api.letsencrypt.org/directory"
      - "--certificatesresolvers.myresolver.acme.email=yogesh.kumar.3@volvo.com"
      - "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
      - "8089:8089"
    volumes:
      - "./letsencrypt:/letsencrypt"
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
    labels:
      - traefik.enable=true
      - traefik.http.routers.dashboard.rule=Host(`traefik.XXX.com`)
      - traefik.http.routers.dashboard.service=api@internal
      - traefik.http.routers.dashboard.middlewares=nztAuth
      # htpasswd -nb admin gc12345! | sed -e s/\\$/\\$\\$/g
      - traefik.http.middlewares.nztAuth.basicauth.users=admin:$$apr1$$kFKBscuH$$Iw5bKwkTgbbxBMFCAS9zo.
  db:
    image: postgres:17
    container_name: sonarqube-db
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: sonar
      POSTGRES_DB: sonarqube
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: always

  sonarqube:
    image: sonarqube:25.3.0.104237-community
    container_name: sonarqube
    ports:
      - "9000:9000"
    environment:
      - SONARQUBE_JDBC_URL=jdbc:postgresql://db:5432/sonarqube
      - SONARQUBE_JDBC_USERNAME=sonar
      - SONARQUBE_JDBC_PASSWORD=sonar
    depends_on:
      - db
    restart: always
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.sonarqube.rule=Host(`web.XXX.com`)"
      - "traefik.http.routers.sonarqube.entrypoints=websecure"
      - "traefik.http.routers.sonarqube.tls.certresolver=myresolver"

volumes:
  postgres_data:
  sonarqube_data:
  sonarqube_extensions:
  sonarqube_logs:

EOL

#sudo ufw allow 9000/tcp
#sudo ufw reload

# Start the containers with Docker Compose
sudo docker-compose up -d