FROM fedora:latest

RUN dnf install --assumeyes \
        git \
        gh \
        gnupg2 \
        openssh-clients \
        git-delta \
    && dnf clean all

WORKDIR /opt/git-setup
COPY . /opt/git-setup
RUN chmod +x git-setup runtime/scripts/* \
    && test -x runtime/scripts/config \
    && test -f runtime/templates/git/config \
    && runtime/scripts/help --help > /dev/null

ENTRYPOINT ["/opt/git-setup/git-setup"]
