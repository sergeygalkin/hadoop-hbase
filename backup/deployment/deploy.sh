#!/bin/bash - 
cd $(dirname $(realpath $0))
ansible-playbook -i hosts backup-deployment.yaml

