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
RUN chmod +x git-setup runtime/scripts/* \
    && test -x runtime/scripts/config \
    && test -f runtime/templates/git/config \
    && runtime/scripts/help --help > /dev/null

ENTRYPOINT ["/opt/git-setup/git-setup"]
