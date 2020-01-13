make make_terraform
make terraform
terraform init
terraform apply
make make_ansible
make install
ssh -o "StrictHostKeyChecking no" -i ~/.aws/ssh-key.pem ubuntu@$(cat terraform/ip_master.txt)
ansible-playbook -i control/inventory.yaml control/install_docker.yaml
ansible-playbook -i control/inventory.yaml control/install_k8s.yaml
ansible-playbook -i control/inventory.yaml control/kubeadm_init.yaml
ansible-playbook -i control/inventory.yaml control/post_init.yaml
ansible-playbook -i control/inventory.yaml control/network.yaml
ansible-playbook -i control/inventory.yaml control/nginx.yaml
kubectl get deploy
kubectl get po
journalctl -f -u kubelet
curl http://$(cat terraform/ip_master.txt)
terraform destroy
