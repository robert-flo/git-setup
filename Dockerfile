FROM archlinux:latest

RUN pacman -Syu --noconfirm --needed \
    git \
    github-cli \
    gnupg \
    openssh \
    git-delta

WORKDIR /opt/git-setup
COPY . /opt/git-setup
RUN chmod +x git-setup runtime/scripts/* \
    && test -x runtime/scripts/config \
    && test -f runtime/templates/git/config \
    && runtime/scripts/help --help > /dev/null

ENTRYPOINT ["/opt/git-setup/git-setup"]
