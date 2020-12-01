FROM ubuntu:20.04

RUN apt-get update && apt-get install -y \
    git \
    neovim \
    openssh-client \
    python3 \
    python3-apt \
    python3-pip \
    python3-venv

# Copy Neovim configuration file.
RUN mkdir -p /root/.config/nvim
COPY ./roles/neovim/files/init.vim /root/.config/nvim/init.vim

RUN pip3 install --upgrade \
    ansible \
    pip \
    python-apt \
    pywinrm \
    setuptools \
    wheel

COPY ./configs/ /etc/ansible/
RUN ansible-galaxy install -r /etc/ansible/requirements.yaml

RUN mkdir /bootware
WORKDIR /bootware

COPY ./main.yaml /bootware/main.yaml
COPY ./roles /bootware/roles

ENTRYPOINT ["/usr/local/bin/ansible-playbook"]
