#!/bin/bash
new_password=$(grep -Po "(?<=password=)[^\s]+" /root/.my.cnf)
alter_command="ALTER USER root@localhost IDENTIFIED BY ;"
mysql --defaults-file=/root/.my.cnf -e "$alter_command"
