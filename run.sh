#!/bin/bash

install_kamailio_5_3() {
	local container_name=$1

	lxc exec $container_name -- dnf -y install dnf-plugins-core
	lxc exec $container_name -- dnf -y config-manager --add-repo https://rpm.kamailio.org/centos/kamailio.repo
	lxc exec $container_name -- dnf -y copr enable irontec/sngrep
	lxc exec $container_name -- dnf -y module reset php
	lxc exec $container_name -- dnf -y module enable php:7.3

	lxc exec $container_name -- dnf -y install --disablerepo=kamailio --enablerepo=kamailio-5.3 kamailio kamailio-mysql kamailio-presence kamailio-ldap kamailio-debuginfo kamailio-xmpp kamailio-unixodbc kamailio-utils kamailio-gzcompress kamailio-tls kamailio-outbound
	lxc exec $container_name -- dnf -y install php php-cli php-common php-mysqlnd php-gd php-curl php-xml php-pear
	lxc exec $container_name -- dnf -y install make
	lxc exec $container_name -- dnf -y install tar
	lxc exec $container_name -- dnf -y install sngrep wget nano mysql-server httpd

	echo "Opening ports in firewall:"
	echo "Opening Port: 80"
	firewall-cmd --query-port=80/tcp || firewall-cmd --add-port=80/tcp
	echo "Opening Port: 443"
	firewall-cmd --query-port=443/tcp || firewall-cmd --add-port=443/tcp
	echo "Opening Port: 5060 tcp"
	firewall-cmd --query-port=5060/tcp || firewall-cmd --add-port=5060/tcp
	echo "Opening Port: 5061 udp"
	firewall-cmd --query-port=5061/udp || firewall-cmd --add-port=5061/udp

	echo "Reloading Firewall Rules"
	firewall-cmd --reload
	firewall-cmd --list-all

	# Add host to container proxy device port entries.
        lxc config device add $container_name httpd proxy listen=tcp:0.0.0.0:80 connect=tcp:0.0.0.0:80
        lxc config device add $container_name tcp5060 proxy listen=tcp:0.0.0.0:5060 connect=tcp:0.0.0.0:5060
        lxc config device add $container_name udp5061 proxy listen=udp:0.0.0.0:5061 connect=udp:0.0.0.0:5061


	echo "Installing Pear and XML_RPC2"
	lxc exec $container_name -- pear channel-update pear.php.net
	lxc exec $container_name -- pear install XML_RPC2

	echo "Installing Siremis Web Interface"
	# Siremis Web Interface
	lxc exec $container_name -- wget https://siremis.asipto.com/pub/downloads/siremis/siremis-5.3.0.tgz
	lxc exec $container_name -- sh -c "tar xvfz siremis-5.3.0.tgz -C /var/www/"
	lxc exec $container_name -- sh -c "make -C /var/www/siremis-5.3.0/ apache24-conf > /etc/httpd/conf.d/siremis.conf"
	lxc exec $container_name -- sed -i '1,3d' /etc/httpd/conf.d/siremis.conf
	lxc exec $container_name -- sed -i '$d;$d;$d' /etc/httpd/conf.d/siremis.conf
	lxc exec $container_name -- make -C /var/www/siremis-5.3.0/ prepare24
	lxc exec $container_name -- chown -R apache:apache /var/www/siremis-5.3.0/siremis

	# Patch kamdbctl.mysql to use the correct path on system.
	lxc exec $container_name -- sh -c "sed -i 's#DATA_DIR=\"/usr/local/share/kamailio\"#DATA_DIR=\"/usr/share/kamailio\"#' /usr/lib64/kamailio//kamctl/kamdbctl.mysql"

	# Start services.
	lxc exec $container_name -- systemctl start httpd
	lxc exec $container_name -- systemctl enable httpd
	lxc exec $container_name -- systemctl status httpd

	lxc exec $container_name -- systemctl start mysqld
	lxc exec $container_name -- systemctl enable mysqld
	lxc exec $container_name -- systemctl status mysqld

	echo "Take Snapshot of system: $container_name-packages_installed"
		lxc snapshot $container_name $container_name-packages_installed
		lxc info $container_name
}

#CONFIGURE
configure_kamailio_5_3() {
	local container_name=$1
	lxc info $container_name
# Starting configuration.
#	lxc exec $container_name -- printenv

	lxc exec $container_name -- sh -c "mysql --defaults-extra-file=/root/mysql_secure.cnf -e \"ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$(printenv MYSQLROOTUSERPASSWORD)';\""







######################
#	echo -e "\n\nUse password: #i&6zTJ6uCpf9P\n\n"
#	lxc exec $container_name -- mysql_secure_installation

	# Get kamailio_setup_default_database.sql from gist.
#	lxc exec $container_name -- sh -c "curl -o /etc/kamailio/kamailio_setup_default_database.sql https://gist.githubusercontent.com/cjemorton/3194c633edb63f136902af598bb43226/raw"
#	lxc exec $container_name -- sh -c "mysql -sfu root -p < /etc/kamailio/kamailio_setup_default_database.sql"

#	# Get kamctlrc from gist
#	lxc exec $container_name -- sh -c "curl -o /etc/kamailio/kamctlrc https://gist.githubusercontent.com/cjemorton/e6b7f07bfb99dc773e8642e10c321e22/raw"

	# Patch /etc/kamailio/kamailio.cfg with correct sql password.
#	lxc exec $container_name -- sh -c "sed -i 's#^#!define DBURL "mysql://kamailio:kamailiorw@localhost/kamailio"##!define DBURL "mysql://kamailio:w526WWmi7Ju7G@localhost/kamailio"#' /etc/kamailio/kamailio.cfg"

#	lxc exec $container_name -- sh -c "kamdbctl create"
#	lxc exec $container_name -- kamctl add 100 100
#	lxc exec $container_name -- systemctl start kamailio
#	lxc exec $container_name -- systemctl enable kamailio
#	lxc exec $container_name -- systemctl status kamailio

#	lxc exec $container_name -- /bin/bash

}
generate_settings_create() {
	touch .settings_kamailio.yaml
	settings_kamailio_yaml=.settings_kamailio.yaml


# MYSQL: MAIN ROOT PASSWORD
# CREATE
	read -p "Do you want to generate a random password for MySQL root user? (y/n, default: y): " generate_password

	case $generate_password in
	  [Yy]*|"")  # If user presses Enter or enters 'y' or 'Y'
	    mysql_root_user_password=$(openssl rand -base64 12 | tr -d '/+=' | head -c 12)
	    ;;
	  [Nn]*)  # If user enters 'n' or 'N'
	    read -s -p "Enter the password for the MySQL root user: " mysql_root_user_password
	    echo ""  # Move to a new line after reading the password
	    ;;
	  *)
	    echo "Invalid input. Exiting."
	    exit 1
	    ;;
	esac

	echo "Password for MySQL root user: $mysql_root_user_password"

	if [ -e "$settings_kamailio_yaml" ]; then
   	 # Append the new password to the YAML file
   	 echo "- mysql_root_user_password: $mysql_root_user_password" >> "$settings_kamailio_yaml"
	else
	    # Create a new YAML file with the password
	    echo "- mysql_root_user_password: $mysql_root_user_password" > "$settings_kamailio_yaml"
	fi
# MYSQL: kamailio user password.
	read -p "Do you want to generate a random password for MySQL kamailio user? (y/n, default: y): " generate_password

        case $generate_password in
          [Yy]*|"")  # If user presses Enter or enters 'y' or 'Y'
            mysql_kamailio_user_password=$(openssl rand -base64 12 | tr -d '/+=' | head -c 12)
            ;;
          [Nn]*)  # If user enters 'n' or 'N'
            read -s -p "Enter the password for the MySQL kamailio user: " mysql_kamailio_user_password
            echo ""  # Move to a new line after reading the password
            ;;
          *)
            echo "Invalid input. Exiting."
            exit 1
            ;;
        esac

	echo "Password for MySQL kamailio user: $mysql_kamailio_user_password"

	if [ -e "$settings_kamailio_yaml" ]; then
         # Append the new password to the YAML file
         echo "- mysql_kamailio_user_password: $mysql_kamailio_user_password" >> "$settings_kamailio_yaml"
        else
            # Create a new YAML file with the password
            echo "- mysql_kamailio_user_password: $mysql_kamailio_user_password" > "$settings_kamailio_yaml"
	fi
# MYSQL: siremis user password.
	read -p "Do you want to generate a random password for MySQL siremis user? (y/n, default: y): " generate_password

        case $generate_password in
          [Yy]*|"")  # If user presses Enter or enters 'y' or 'Y'
            mysql_siremis_user_password=$(openssl rand -base64 12 | tr -d '/+=' | head -c 12)
            ;;
          [Nn]*)  # If user enters 'n' or 'N'
            read -s -p "Enter the password for the MySQL siremis user: " mysql_siremis_user_password
            echo ""  # Move to a new line after reading the password
            ;;
          *)
            echo "Invalid input. Exiting."
            exit 1
            ;;
        esac

	echo "Password for MySQL siremis user: $mysql_siremis_user_password"

        if [ -e "$settings_kamailio_yaml" ]; then
         # Append the new password to the YAML file
         echo "- mysql_siremis_user_password: $mysql_siremis_user_password" >> "$settings_kamailio_yaml"
        else
            # Create a new YAML file with the password
            echo "- mysql_siremis_user_password: $mysql_siremis_user_password" > "$settings_kamailio_yaml"
        fi
# MYSQL: kamailioro user password.
	read -p "Do you want to generate a random password for MySQL kamailioro user? (y/n, default: y): " generate_password

        case $generate_password in
          [Yy]*|"")  # If user presses Enter or enters 'y' or 'Y'
            mysql_kamailioro_user_password=$(openssl rand -base64 12 | tr -d '/+=' | head -c 12)
            ;;
          [Nn]*)  # If user enters 'n' or 'N'
            read -s -p "Enter the password for the MySQL kamailioro user: " mysql_kamailioro_user_password
            echo ""  # Move to a new line after reading the password
            ;;
          *)
            echo "Invalid input. Exiting."
            exit 1
            ;;
        esac

	echo "Password for MySQL kamailioro user: $mysql_kamailioro_user_password"

        if [ -e "$settings_kamailio_yaml" ]; then
         # Append the new password to the YAML file
         echo "- mysql_kamailioro_user_password: $mysql_kamailioro_user_password" >> "$settings_kamailio_yaml"
        else
            # Create a new YAML file with the password
            echo "- mysql_kamailioro_user_password: $mysql_kamailioro_user_password" > "$settings_kamailio_yaml"
        fi
}


# Set Environment Variables and Display Settings.
generate_settings_display() {
	local container_name=$1
	settings_file=.settings_kamailio.yaml

# Check if the settings file exists
if [ -e "$settings_file" ]; then
    # Loop over each line in the file
    while IFS= read -r line; do
        # Extract everything before and after ':'
        key="${line%%:*}"
        value="${line#*: }"

        # Trim leading and trailing spaces from key and value
        key="$(echo "$key" | awk '{$1=$1;print}')"
        value="$(echo "$value" | awk '{$1=$1;print}')"

        # Remove hyphens and underscores, capitalize key, and replace spaces with underscores
        key="$(echo "$key" | sed -e 's/[-_]//g' | awk '{print toupper($0)}' | tr -d '[:space:]' | sed 's/[[:space:]]/_/g')"

        # Print the variables
        echo "$key: $value"

        # Set variables with extracted values
	lxc config set $container_name environment.${key} "$value"
        declare "${key}=$value"

    done < "$settings_file"
else
    echo "Settings file $settings_file not found."
fi

##lxc exec $container_name -- printenv

}
generate_settings() {
	local container_name=$1
	settings_kamailio_yaml=.settings_kamailio.yaml
	if [ -e "$settings_kamailio_yaml" ]; then
	    read -p "Do you want to delete $settings_kamailio_yaml? (yes/no) " answer

	    case "$answer" in
	        [Yy]|[Yy][Ee][Ss])
	            rm "$settings_kamailio_yaml"
	            echo "File deleted, creating new."
		    generate_settings_create $container_name
	            ;;
	        [Nn]|[Nn][Oo])
		    generate_settings_display $container_name
	            ;;
	        *)
	            echo "Invalid input. File not deleted."
	            ;;
	    esac
	else
	    echo "The file $settings_kamailio_yaml does not exist."
	fi
}
create_container() {
    echo "Creating new LXC container: $container_name"
    lxc launch images:rockylinux/8/amd64 $container_name
}

check_connectivity() {
    local container_name=$1

    echo "Checking outward connectivity for $container_name."
    while ! lxc exec $container_name -- ping -c 3 1.1.1.1 &> /dev/null; do
        echo "Outward connectivity not detected. Retrying..."
	lxc ls
        sleep 5
    done

    echo "Ping Successful!"
	lxc ls
}
install_ssh() {
   local container_name=$1
	echo "$container_name - Installing openssh and launching it"
       lxc exec $container_name -- echo "172.16.0.1" >> /etc/resolv.conf
       lxc exec $container_name -- echo "8.8.8.8" >> /etc/resolv.conf
       lxc exec $container_name -- dnf -y update
       lxc exec $container_name -- dnf -y install openssh-server
       lxc exec $container_name -- systemctl start sshd
       lxc exec $container_name -- systemctl enable sshd
       lxc exec $container_name -- echo "a3f6c123" | passwd --stdin root
#       lxc console $container_name
}

check_rocky_linux_version() {
    if [ -e /etc/os-release ]; then
        source /etc/os-release
        if [ "$ID" == "rocky" ]; then
            echo "Rocky Linux version: $VERSION_ID"
        else
            echo "This system is not running Rocky Linux. Detected OS: $ID"

	    echo "This script was written to work on Rocky Linux 8.9, if it doesn't work on your system please modify it accordingly."
            exit 1
        fi
    else
        echo "Unable to determine the OS version. /etc/os-release file not found."
        exit 1
    fi
}

# #########################
# Program Start.
# #########################

# Check the system to make sure its running on a compatable system.
check_rocky_linux_version
# Get container name from the terminal, check to see if it exists.
container_name="$1"

# Check if the container exists
if lxc list --format csv | grep $container_name &> /dev/null; then

    if [ "$#" -ge 2 ] && [ "$2" = "-r" ]; then
	echo "Rolling back to initial fresh-snapshot"
	lxc restore $container_name $container_name-fresh-snapshot
	check_connectivity $container_name
    fi

   if [ "$#" -ge 2 ] && [ "$2" = "-k" ]; then
        echo "Rolling back to fresh snapshot and, Installing Kamailio"
	lxc restore $container_name $container_name-fresh-snapshot
	check_connectivity $container_name
	install_kamailio_5_3 $container_name
#	configure_kamailio_5_3 $container_name
   fi
   if [ "$#" -ge 2 ] && [ "$2" = "-c" ]; then
        check_connectivity $container_name
	echo "Restoring From Snapshot, starting configuration."
        lxc restore $container_name $container_name-packages_installed
	generate_settings_display $container_name
        configure_kamailio_5_3 $container_name
   fi

   if [ "$#" -ge 2 ] && [ "$2" = "-s" ]; then
	generate_settings $container_name
   fi

else

	if [ -z "$1" ]; then
	    echo "Welcome to the Install Script: Tell me what to do with these options"
		lxc ls
		echo "-n : Creates a new lxc container, and takes a snapshot"
		echo "<container_name> -s : Generate settings file"
		echo "<container_name> -r : Roll back to a fresh snapshot"
		echo "<container_name> -k : Roll back to a fresh snapshot, and install kamailio"
		echo "<container_name> -c : Roll back to a fresh snapshot of all packages installed - start patching and configuation."

	elif [ "$1" = "-n" ]; then
	    echo "You chose '-n'. : Running commands."
		echo "Container $container_name does not exist."
		container_name="Rocky8-$(uuidgen | cut -f 2 -d '-')"
		echo "Creating: $container_name"
		create_container
		check_connectivity $container_name
		install_ssh $container_name
		# Create an initial snapshot.
		echo "Creating initial fresh-snapshot"
		lxc snapshot $container_name $container_name-fresh-snapshot
		lxc info $container_name
	else
	    echo "Oops! Command provided doesn't match anything."
	fi
fi

