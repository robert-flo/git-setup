FROM ubuntu:latest

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        git \
        gh \
        gnupg \
        openssh-client \
        git-delta \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/git-setup
COPY . /opt/git-setup
RUN chmod +x git-setup scripts/*

ENTRYPOINT ["/opt/git-setup/git-setup"]
