build:
	docker build . -t albeego/apt-repository-action:0.0.1
push:
	docker push albeego/apt-repository-action:0.0.1