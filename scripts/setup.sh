#!/bin/bash
sudo /tmp/scripts/update_apt.sh

# Установка переменных окружения
set -e

set -a
source /tmp/resources/.env
set +a

# Установка зависимостей
echo "INSTALLING DEPENDENCIES"
sudo apt update
sudo apt install -y openjdk-17-jdk curl gnupg2 git docker.io
sudo apt install npm -y


sudo apt remove -y nodejs libnode-dev
sudo rm -rf /etc/apt/sources.list.d/nodesource.list
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Установка Jenkins
echo "INSTALLING JENKINS"
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update
sudo apt install -y jenkins

# Добавляем Jenkins в группу Docker
echo "SETTING UP JENKINS"
sudo usermod -aG docker jenkins

# Создание groovy-скрипта для автологина
sudo mkdir -p /var/lib/jenkins/init.groovy.d
cat <<EOF | sudo tee /var/lib/jenkins/init.groovy.d/basic-security.groovy
#!groovy

import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()

println "--> creating local user '$JENKINS_USER'"

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("${JENKINS_USER}", "${JENKINS_PASS}")
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

instance.save()
EOF

# Запуск Jenkins
sudo systemctl enable jenkins
sudo systemctl restart jenkins

echo "STARTING UP JENKINS..."
while ! curl -s http://localhost:8080/login > /dev/null; do sleep 5; done

# Загрузка Jenkins CLI
wget -q http://localhost:8080/jnlpJars/jenkins-cli.jar -O /tmp/resources/jenkins-cli.jar

# Установка необходимых плагинов
echo "INSTALLING PLUGINS"
PLUGINS=("git" "docker-workflow" "workflow-aggregator" "blueocean" "github")
for plugin in "${PLUGINS[@]}"; do
  java -jar /tmp/resources/jenkins-cli.jar -s http://localhost:8080 -auth $JENKINS_USER:$JENKINS_PASS install-plugin $plugin
done

# Перезапуск Jenkins после установки плагинов
java -jar /tmp/resources/jenkins-cli.jar -s http://localhost:8080 -auth $JENKINS_USER:$JENKINS_PASS safe-restart

echo "WAITING FOR JENKINS TO RESTART"
until java -jar /tmp/resources/jenkins-cli.jar -s http://localhost:8080 -auth $JENKINS_USER:$JENKINS_PASS who-am-i > /dev/null 2>&1; do
  echo "  ... Jenkins not ready yet, wait 5 more seconds"
  sleep 5
done

# Включаем обработку GitHub webhook
cat <<EOF | sudo tee /var/lib/jenkins/org.jenkinsci.plugins.github.config.GitHubPluginConfig.xml
<org.jenkinsci.plugins.github.config.GitHubPluginConfig plugin="github@1.37.3">
  <configs/>
  <hookUrl>http://$(hostname -I | awk '{print $1}'):8080/github-webhook/</hookUrl>
</org.jenkinsci.plugins.github.config.GitHubPluginConfig>
EOF

sudo chown jenkins:jenkins /var/lib/jenkins/org.jenkinsci.plugins.github.config.GitHubPluginConfig.xml

# Создание Jenkins Job
envsubst < /tmp/resources/jenkins_job_config.xml > /tmp/resources/job_config_ready.xml
java -jar /tmp/resources/jenkins-cli.jar -s http://localhost:8080 -auth $JENKINS_USER:$JENKINS_PASS create-job auto-docker < /tmp/resources/job_config_ready.xml

echo "Jenkins is READY!"