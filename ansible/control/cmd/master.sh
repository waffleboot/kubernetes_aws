#!/bin/bash

ansible-playbook -i control/inventory.yaml control/install_docker.yaml
ansible-playbook -i control/inventory.yaml control/install_k8s.yaml
ansible-playbook -i control/inventory.yaml control/kubeadm_init.yaml
ansible-playbook -i control/inventory.yaml control/post_init.yaml
ansible-playbook -i control/inventory.yaml control/network.yaml
ansible-playbook -i control/inventory.yaml control/nginx.yaml
