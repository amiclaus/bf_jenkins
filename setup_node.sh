#!/bin/bash
set -e

#----------------------------------#
# Global definitions section       #
#----------------------------------#

SCRIPT_DIR="$(readlink -f $(dirname $0))"

USER=admin
PASS=admin

USER_FILE=/etc/jenkins-user
PASS_FILE=/etc/jenkins-pass

MASTER_USER=jenkins
MASTER_PASS=analog

# Login info for to connect to the Jenkins master
MASTER_USER_FILE=/etc/jenkins-user-master
MASTER_PASS_FILE=/etc/jenkins-pass-master

source $SCRIPT_DIR/lib/utils.sh

if [ `id -u` == "0" ]
then
	echo_red "This script should not be run as root" 1>&2
	exit 1
fi

disable_sudo_passwd() {
	sudo_required
	sudo -s <<-EOF
		if ! grep -q $USER /etc/sudoers ; then
			echo "$USER	ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
		fi
	EOF
}

apt_install_prereqs() {
	sudo_required
	sudo -s <<-EOF
		apt-get update
		apt-get install -y default-jdk curl git htpdate
		apt-get -y upgrade
		/etc/init.d/htpdate restart
	EOF
}

install_jenkins() {
	sudo_required
	sudo -s <<-EOF
		wget -q -O - https://jenkins-ci.org/debian/jenkins-ci.org.key | apt-key add -
		echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list
		apt-get update
		apt-get install -y jenkins

		# Avoid setup wizard
		if ! grep -q runSetupWizard /etc/default/jenkins ; then
			echo JAVA_ARGS=\"\\\$JAVA_ARGS -Djenkins.install.runSetupWizard=false\" >> /etc/default/jenkins
		fi

		echo $USER > $USER_FILE
		echo $PASS > $PASS_FILE

		mkdir -p /usr/share/jenkins/ref/init.groovy.d/
		cp -f $SCRIPT_DIR/lib/jenkins_security.groovy /usr/share/jenkins/ref/init.groovy.d/security.groovy

		# Check if this is Ubuntu ; open up a firewall rule
		if type ufw &> /dev/null ; then
			ufw allow 8080
			ufw enable
		fi
	EOF
}

install_jenkins_plugins() {
	sudo $SCRIPT_DIR/batch-install-jenkins-plugins.sh \
		--plugins $SCRIPT_DIR/jenkins_plugins.txt \
		--plugindir /var/lib/jenkins/plugins
}

install_swarm_service() {
	sudo -s <<-EOF
		echo $MASTER_USER > $MASTER_USER_FILE
		echo $MASTER_PASS > $MASTER_PASS_FILE

		cp $SCRIPT_DIR/lib/jenkins_swarm_client.service /lib/systemd/system
		ln -sf /lib/systemd/system/jenkins_swarm_client.service  /etc/systemd/system/jenkins_swarm_client.service

		cp $SCRIPT_DIR/lib/jenkins_swarm_client.init /etc/init.d/jenkins_swarm_client
		chmod +x /etc/init.d/jenkins_swarm_client

		systemctl enable jenkins_swarm_client
	EOF
}

disable_sudo_passwd

apt_install_prereqs

install_jenkins

install_jenkins_plugins

install_swarm_service

sudo /etc/init.d/jenkins restart
