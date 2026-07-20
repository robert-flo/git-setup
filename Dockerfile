FROM archlinux:latest

RUN pacman -Syu --noconfirm --needed \
    git \
    github-cli \
    gnupg \
    openssh \
    git-delta

WORKDIR /opt/git-setup
COPY . /opt/git-setup
RUN chmod +x git-setup scripts/*

ENTRYPOINT ["/opt/git-setup/git-setup"]
