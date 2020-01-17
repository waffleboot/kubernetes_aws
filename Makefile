public_master_ip  = $(shell cat terraform/public_master_ip)
public_worker_ip  = $(shell cat terraform/public_worker_ip)

build: apply ssh_config install

make_terraform:
	docker build -t yangand/kubernetes_terraform terraform/docker

test_terraform:
	docker run --rm -it yangand/kubernetes_terraform

make_ansible:
	docker build -t yangand/kubernetes_ansible ansible/docker

test_ansible:
	docker run --rm -it yangand/kubernetes_ansible

apply:
	docker run --rm --name terraform -w /opt -v ${PWD}/terraform:/opt -v ~/.aws:/root/.aws yangand/kubernetes_terraform terraform apply -auto-approve
	sleep 60

destroy:
	docker run --rm --name terraform -w /opt -v ${PWD}/terraform:/opt -v ~/.aws:/root/.aws yangand/kubernetes_terraform terraform destroy -auto-approve

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
	-i /ansible/install/inventory.yaml \
	/ansible/install/install_python.yaml \
	/ansible/control/install_docker.yaml \
	/ansible/control/install_k8s.yaml \
	/ansible/control/install_helm.yaml \
	/ansible/control/kubeadm_init.yaml \
	/ansible/control/kubeadm_join.yaml \
	/ansible/control/network.yaml

reset:
	docker run --rm --name ansible -it \
	-v ${PWD}/ansible:/ansible \
	-v ${PWD}/terraform:/terraform \
	-v /Users/yangand/.aws:/.aws \
	yangand/kubernetes_ansible ansible-playbook \
	--extra-vars public_master_ip=$(public_master_ip) \
	--extra-vars public_worker_ip=$(public_worker_ip) \
	-i /ansible/install/inventory.yaml \
	/ansible/reset/playbook.yaml

clean:
	docker image prune -a

ssh_config:
	~/go/bin/ssh_config ~/.ssh master $(public_master_ip) ubuntu ~/.aws/id_rsa_master
	~/go/bin/ssh_config ~/.ssh worker $(public_worker_ip) ubuntu ~/.aws/id_rsa_worker
