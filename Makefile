public_master_ip  = $(shell cat terraform/public_master_ip)
public_worker_ip  = $(shell cat terraform/public_worker_ip)
private_master_ip = $(shell cat terraform/private_master_ip)
private_worker_ip = $(shell cat terraform/private_worker_ip)

make_terraform:
	docker build -t yangand/kubernetes_terraform terraform/docker

test_terraform:
	docker run --rm -it yangand/kubernetes_terraform

make_ansible:
	docker build -t yangand/kubernetes_ansible ansible/docker

test_ansible:
	docker run --rm -it yangand/kubernetes_ansible

terraform:
	docker run --rm --name terraform -it -w /opt -v ${PWD}/terraform:/opt -v ~/.aws:/root/.aws yangand/kubernetes_terraform

ansible:
	docker run --rm --name ansible -it -v ${PWD}/ansible:/ansible -v /Users/yangand/.aws:/.aws yangand/kubernetes_ansible

install:
	docker run --rm --name ansible -it \
	-v ${PWD}/ansible:/ansible \
	-v ${PWD}/terraform:/terraform \
	-v /Users/yangand/.aws:/.aws \
	yangand/kubernetes_ansible ansible-playbook \
	--extra-vars public_master_ip=$(public_master_ip) \
	--extra-vars public_worker_ip=$(public_worker_ip) \
	--extra-vars private_master_ip=$(private_master_ip) \
	--extra-vars private_worker_ip=$(private_worker_ip) \
	-i /ansible/install/inventory.yaml \
	/ansible/install/install_python.yaml \
	/ansible/install/copy_to_remote.yaml \
	/ansible/control/install_docker.yaml \
	/ansible/control/install_k8s.yaml \
	/ansible/control/kubeadm_init.yaml \
	/ansible/control/kubeadm_join.yaml \
	/ansible/control/network.yaml \
	/ansible/control/nginx.yaml

master:
	ssh -o "StrictHostKeyChecking no" -i ~/.aws/id_rsa_master ubuntu@$(ip_master)

worker:
	ssh -o "StrictHostKeyChecking no" -i ~/.aws/id_rsa_worker ubuntu@$(ip_worker)

clean:
	docker image prune -a

ssh_config:
	~/go/bin/ssh_config ~/.ssh master $(ip_master) ubuntu ~/.aws/id_rsa_master
	~/go/bin/ssh_config ~/.ssh worker $(ip_worker) ubuntu ~/.aws/id_rsa_worker
