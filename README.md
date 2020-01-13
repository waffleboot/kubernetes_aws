make make_terraform
make terraform
terraform init
terraform apply
copy instance_ip_addr to install/inventory.yaml
sed -i '' -e "s/IP_ADDRESS/$(cat terraform/ip_address.txt)/g" ansible/install/inventory.yaml
make make_ansible
make install
ssh -o "StrictHostKeyChecking no" -i ~/.aws/ssh-key.pem ubuntu@$(cat terraform/ip_address.txt)
ansible-playbook -i control/inventory.yaml control/install.yaml
ansible-playbook -i control/inventory.yaml control/kubeadm_init.yaml
ansible-playbook -i control/inventory.yaml control/post_init.yaml
ansible-playbook -i control/inventory.yaml control/network.yaml
ansible-playbook -i control/inventory.yaml control/nginx.yaml
kubectl get deploy
kubectl get po
journalctl -f -u kubelet
curl http://$(cat terraform/ip_address.txt)
terraform destroy
