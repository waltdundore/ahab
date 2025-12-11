#!/usr/bin/env bash
function deploy_mysql() {
    echo "Deploying MySQL"
    systemctl start mysql
    systemctl enable mysql
}

