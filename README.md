make make_terraform
make terraform

terraform init

terraform apply

make make_ansible

make install

journalctl -f -u kubelet

terraform destroy
