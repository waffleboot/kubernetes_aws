#!/bin/bash

token=123

ansible-playbook -i control/inventory.yaml control/install_docker.yaml
ansible-playbook -i control/inventory.yaml control/install_k8s.yaml
ansible-playbook --extra-vars token=${token} -i control/inventory.yaml control/kubeadm_join.yaml
ansible-playbook -i control/inventory.yaml control/network.yaml
