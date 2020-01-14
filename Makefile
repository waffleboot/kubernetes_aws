ip_master = $(shell cat terraform/ip_master.txt)
ip_worker = $(shell cat terraform/ip_worker.txt)

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
	--extra-vars ip_master=$(ip_master) --extra-vars ip_worker=$(ip_worker) \
	-i /ansible/install/inventory.yaml \
	/ansible/install/install_python.yaml \
	/ansible/install/copy_to_remote.yaml

master:
	ssh -o "StrictHostKeyChecking no" -i ~/.aws/id_master_rsa ubuntu@$(ip_master)

worker:
	ssh -o "StrictHostKeyChecking no" -i ~/.aws/id_worker_rsa ubuntu@$(ip_worker)

clean:
	docker image prune -a

ssh_config:
	~/go/bin/ssh_config ~/.ssh master $(ip_master) ubuntu ~/.aws/id_rsa_master
	~/go/bin/ssh_config ~/.ssh worker $(ip_worker) ubuntu ~/.aws/id_rsa_worker
