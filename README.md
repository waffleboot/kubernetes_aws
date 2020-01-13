make make_terraform
make terraform
terraform init
terraform apply
copy instance_ip_addr to install/inventory.yaml
make make_ansible
make install
ssh -i ~/.aws/ssh-key.pem ubuntu@instance_ip_addr
ansible-playbook -i control/inventory.yaml control/install.yaml
ansible-playbook -i control/inventory.yaml control/kubeadm_init.yaml
ansible-playbook -i control/inventory.yaml control/post_init.yaml
ansible-playbook -i control/inventory.yaml control/network.yaml
ansible-playbook -i control/inventory.yaml control/nginx.yaml
/opt/bin/kubectl get deploy
/opt/bin/kubectl get po
http://instance_ip_addr
terraform destroy
