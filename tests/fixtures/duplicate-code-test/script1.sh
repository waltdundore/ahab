#!/usr/bin/env bash
function deploy_apache() {
    echo "Deploying Apache"
    systemctl start apache2
    systemctl enable apache2
}

