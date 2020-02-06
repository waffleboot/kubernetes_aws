public_master_ip  = $(shell cat terraform/public_master_ip)
public_worker_ip  = $(shell cat terraform/public_worker_ip)
public_master_dns = $(shell cat terraform/public_master_dns)
kubernetes_security_group = $(shell cat terraform/kubernetes-security-group)

all: apply start install registry stop

make_terraform:
	docker build -t yangand/kubernetes_terraform terraform/docker

test_terraform:
	${docker_run} yangand/kubernetes_terraform

make_ansible:
	docker build -t yangand/kubernetes_ansible ansible/docker

test_ansible:
	${docker_run} yangand/kubernetes_ansible

docker_run = docker run --rm -it

apply:
	${docker_run} --name terraform -w /opt -v ${PWD}/terraform:/opt -v ~/.aws:/root/.aws yangand/kubernetes_terraform terraform apply -auto-approve
	sleep 15
	$(MAKE) ssh_config

destroy:
	${docker_run} --name terraform -w /opt -v ${PWD}/terraform:/opt -v ~/.aws:/root/.aws yangand/kubernetes_terraform terraform destroy -auto-approve

terraform:
	${docker_run} --name terraform -it -w /opt -v ${PWD}/terraform:/opt -v ~/.aws:/root/.aws yangand/kubernetes_terraform

ansible:
	${docker_run} --name ansible -it -v ${PWD}/ansible:/ansible -v ${HOME}/.aws:/.aws yangand/kubernetes_ansible

registry:
	${run_ansible} /ansible/control/registry.yaml
	kubectl create -f ansible/control/k8s/registry.yaml
	docker pull nginx
	docker tag nginx ${public_master_dns}:30000/nginx
	sleep 10
	-docker push ${public_master_dns}:30000/nginx

nginx:
	kubectl create -f ansible/control/k8s/nginx.yaml

start:
	-${docker_run} --name ansible -d \
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
	--extra-vars public_master_dns=$(public_master_dns) \
	--extra-vars kubernetes_security_group=$(kubernetes_security_group) \
	-i /ansible/install/inventory.yaml

python:
	${run_ansible} /ansible/install/install_python.yaml

containerd:
	${run_ansible} /ansible/control/install_containerd.yaml

network:
	${run_ansible} /ansible/control/install_network.yaml

k8s:
	${run_ansible} /ansible/control/install_k8s.yaml

kubeadm:
	${run_ansible} /ansible/control/kubeadm_init.yaml /ansible/control/kubeadm_join.yaml
	$(MAKE)	local_kubectl

local_kubectl:
	${run_ansible} /ansible/control/user_admin.yaml
	kubectl config set-cluster kubernetes --server=https://$(public_master_ip):6443
	kubectl config set-cluster kubernetes --certificate-authority=ansible/ca.crt --embed-certs=true
	kubectl config set-credentials yangand --client-certificate=ansible/yangand.crt  --client-key=ansible/yangand.key --embed-certs=true
	kubectl config set-context kubernetes-yangand --cluster=kubernetes --user=yangand
	kubectl config use-context kubernetes-yangand
	rm ansible/yangand.crt
	rm ansible/yangand.key
	rm ansible/ca.crt

install: python containerd network k8s kubeadm
	${run_ansible} /ansible/control/install_helm.yaml
	$(MAKE) kubernetes_git

reset:
	${run_ansible} /ansible/reset/reset.yaml

kubernetes_git:
	${run_ansible} /ansible/control/git.yaml

clean:
	docker image prune -a

ssh_config:
	~/go/bin/ssh_config ~/.ssh master $(public_master_ip) ubuntu ~/.aws/id_rsa_master
	~/go/bin/ssh_config ~/.ssh worker $(public_worker_ip) ubuntu ~/.aws/id_rsa_worker
