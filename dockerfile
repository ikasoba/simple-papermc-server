FROM ubuntu:latest

# --build-arg hoge=fuga
ARG VERSION=""
ARG BUILD_NUM=""
ARG BUILD_NAME=""

# to enable: -e EULA=true
ENV EULA="false"
ENV OPTION=""

SHELL ["/bin/bash", "-c"]

# install dependencies
RUN apt update -y \
&&  apt install -y jq curl software-properties-common ca-certificates apt-transport-https

RUN (curl https://apt.corretto.aws/corretto.key | apt-key add -) \
;   add-apt-repository -y 'deb https://apt.corretto.aws stable main' \
;   apt update -y

RUN curl -fO https://gist.githubusercontent.com/ikasoba/01d12ac14449f513a54aebc178486a82/raw/bf084d0dd0563ad5cbae9e1931fb8a0a7ac8c559/version_comparator.sh \
&&  . ./version_comparator.sh \
&&  if cmp_version_le "$VERSION" "1.17.1" || cmp_version_ge "$VERSION" "1.18" || [ "$VERSION" = "" ]; then \
      apt install -y java-17-amazon-corretto-jdk \
;   elif cmp_version_le "$VERSION" "1.11"; then \
      apt install -y java-8-amazon-corretto-jdk \
;   elif cmp_version_le "$VERSION" "1.16.4"; then \
      apt install -y java-11-amazon-corretto-jdk \
;   elif [ "$VERSION" = "1.16.5" ]; then \
      apt install -y java-16-amazon-corretto-jdk \
;   fi

# create user for minecraft
RUN useradd -m mc
USER mc

# download server jar
WORKDIR /usr/local/src/papermc
RUN if [ "$VERSION" = "" ] || [ "${BUILD_NUM}" = "" ] || [ "${BUILD_NAME}" = "" ]; then \
      if [ "${VERSION}" = "" ]; then \
            VERSION=$(curl https://api.papermc.io/v2/projects/paper | jq -r .versions[-1]) \
;     fi \
;     if [ "${BUILD_NAME}" = "" ] || [ "${BUILD_NUM}" = "" ]; then \
            LAST_BUILD=$(curl https://api.papermc.io/v2/projects/paper/versions/$VERSION/builds | jq .builds[-1]) \
;           BUILD_NUM=$(echo $LAST_BUILD | jq .build) \
;           BUILD_NAME=$(echo $LAST_BUILD | jq -r .downloads.application.name) \
;     fi \
;   fi \
;   curl -f https://api.papermc.io/v2/projects/paper/versions/$VERSION/builds/$BUILD_NUM/downloads/$BUILD_NAME -o paper.jar \
;   chmod o+rx ./paper.jar

WORKDIR /home/mc
ENTRYPOINT  if [ -z "$(ls)" ]; then (echo "initializing..."; java -jar /usr/local/src/papermc/paper.jar > /dev/null) fi \
;           sed -i "s/eula=false/eula=$EULA/" eula.txt \
&&          java $OPTION -jar /usr/local/src/papermc/paper.jar