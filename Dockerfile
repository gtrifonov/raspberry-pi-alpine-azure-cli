FROM resin/raspberry-pi-alpine-python:latest

ARG CLI_VERSION

# Metadata as defined at http://label-schema.org
ARG BUILD_DATE
Run git clone https://github.com/Azure/azure-cli.git /azure-cli
WORKDIR /azure-cli

# pip wheel - required for CLI packaging
# jmespath-terminal - we include jpterm as a useful tool
RUN pip install --no-cache-dir --upgrade pip wheel jmespath-terminal
# bash gcc make openssl-dev libffi-dev musl-dev - dependencies required for CLI
# jq - we include jq as a useful tool
# openssh - included for ssh-keygen
# ca-certificates
RUN apk add --no-cache bash gcc make openssl-dev libffi-dev musl-dev jq openssh \
    ca-certificates curl openssl git && update-ca-certificates
# We also, install jp
RUN curl https://github.com/jmespath/jp/releases/download/0.1.2/jp-linux-amd64 -o /usr/local/bin/jp && chmod +x /usr/local/bin/jp

# 1. Build packages and store in tmp dir
# 2. Install the cli and the other command modules that weren't included
# 3. Temporary fix - install azure-nspkg to remove import of pkg_resources in azure/__init__.py (to improve performance)
RUN /bin/bash -c 'TMP_PKG_DIR=$(mktemp -d); \
    for d in src/azure-cli src/azure-cli-core src/azure-cli-nspkg src/azure-cli-command_modules-nspkg src/command_modules/azure-cli-*/; \
    do cd $d; echo $d; python setup.py bdist_wheel -d $TMP_PKG_DIR; cd -; \
    done; \
    [ -d privates ] && cp privates/*.whl $TMP_PKG_DIR; \
    all_modules=`find $TMP_PKG_DIR -name "*.whl"`; \
    pip install --no-cache-dir $all_modules; \
    pip install --no-cache-dir --force-reinstall --upgrade azure-nspkg azure-mgmt-nspkg;'

# Tab completion
RUN cat /azure-cli/az.completion > ~/.bashrc

WORKDIR /

CMD bash
