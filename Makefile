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
	docker run --rm --name ansible -it -w /opt -v ${PWD}/ansible/install:/opt -v /Users/yangand/.aws:/root/.aws yangand/kubernetes_ansible

install:
	docker run --rm --name ansible -it -w /opt -v ${PWD}/ansible/install:/opt -v /Users/yangand/.aws:/root/.aws yangand/kubernetes_ansible ansible-playbook -i ./inventory.yaml playbook.yaml

clean:
	docker image prune -a
