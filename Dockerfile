FROM ubuntu:18.04
RUN apt-get update
RUN apt-get install -y \
	build-essential \
	software-properties-common
RUN yes "" | add-apt-repository ppa:git-core/ppa && apt update && yes "y" | apt install -y git
RUN apt install -y crossbuild-essential-arm64 debhelper
RUN DEBIAN_FRONTEND=noninteractive apt-get install \
	devscripts \
	build-essential \
	lintian -y
ENV TZ=Europe/London
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get install \
	python3 \
	python3-pip \
	python3-novaclient \
	python3-openstackclient \
	python3-swiftclient -y
RUN apt-get install \
	apt-utils -y
RUN apt-get install \
	wget -y
ENTRYPOINT ["/entrypoint.sh"]