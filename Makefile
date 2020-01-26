public_master_ip  = $(shell cat terraform/public_master_ip)
public_worker_ip  = $(shell cat terraform/public_worker_ip)

build: apply

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
	sleep 5
	$(MAKE) ssh_config start install_python install

destroy:
	docker run --rm --name terraform -w /opt -v ${PWD}/terraform:/opt -v ~/.aws:/root/.aws yangand/kubernetes_terraform terraform destroy -auto-approve

terraform:
	docker run --rm --name terraform -it -w /opt -v ${PWD}/terraform:/opt -v ~/.aws:/root/.aws yangand/kubernetes_terraform

ansible:
	docker run --rm --name ansible -it -v ${PWD}/ansible:/ansible -v ${HOME}/.aws:/.aws yangand/kubernetes_ansible

start:
	docker run --rm --name ansible -d \
	-v ${PWD}/ansible:/ansible \
	-v ${PWD}/terraform:/terraform \
	-v ${HOME}/.aws:/.aws \
	-v ${HOME}/go:/go \
	yangand/kubernetes_ansible tail -f /dev/null

stop:
	docker stop ansible

run_ansible = \
	docker exec -it ansible ansible-playbook \
	--extra-vars public_master_ip=$(public_master_ip) \
	--extra-vars public_worker_ip=$(public_worker_ip) \
	-i /ansible/install/inventory.yaml

install_python:
	${run_ansible} /ansible/install/install_python.yaml

install_containerd:
	${run_ansible} /ansible/control/install_containerd.yaml

install_network:
	${run_ansible} /ansible/control/install_network.yaml

install_k8s:
	${run_ansible} /ansible/control/install_k8s.yaml

install: install_python install_containerd install_network install_k8s
	${run_ansible} \
	/ansible/control/install_helm.yaml \
	/ansible/control/kubeadm_init.yaml \
	/ansible/control/kubeadm_join.yaml \
	/ansible/control/user_admin.yaml \
	/ansible/control/git.yaml
	kubectl config set-cluster kubernetes --server=https://$(public_master_ip):6443
	kubectl config set-cluster kubernetes --certificate-authority=ansible/ca.crt --embed-certs=true
	kubectl config set-credentials yangand --client-certificate=ansible/yangand.crt  --client-key=ansible/yangand.key --embed-certs=true
	kubectl config set-context kubernetes-yangand --cluster=kubernetes --user=yangand
	kubectl config use-context kubernetes-yangand
	rm ansible/yangand.crt
	rm ansible/yangand.key
	rm ansible/ca.crt

reset:
	${run_ansible} /ansible/reset/reset.yaml

clean:
	docker image prune -a

ssh_config:
	~/go/bin/ssh_config ~/.ssh master $(public_master_ip) ubuntu ~/.aws/id_rsa_master
	~/go/bin/ssh_config ~/.ssh worker $(public_worker_ip) ubuntu ~/.aws/id_rsa_worker
