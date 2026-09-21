# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  # ==========================================================
  # Ubuntu
  # ==========================================================

  config.vm.box = "ubuntu/jammy64"

  # Allow enough time for Ubuntu to boot
  config.vm.boot_timeout = 600

  # Don't check for box updates every time
  config.vm.box_check_update = false


  # ==========================================================
  # NETWORK
  # ==========================================================

  # VM accessible from host at:
  # http://localhost:8080
  config.vm.network "forwarded_port",
    guest: 80,
    host: 8080,
    host_ip: "127.0.0.1"


  # ==========================================================
  # VIRTUALBOX
  # ==========================================================

  config.vm.provider "virtualbox" do |vb|

    vb.name = "Ubuntu-DevOps-Lab"

    # 4 GB RAM
    vb.memory = 4098

    # 4 CPU cores
    vb.cpus = 4

    # Set false after confirming the VM works
    vb.gui = false

  end


  # ==========================================================
  # SSH
  # ==========================================================

  config.ssh.username = "vagrant"
  config.ssh.insert_key = true


  # ==========================================================
  # SYNCED FOLDER
  # ==========================================================

  config.vm.synced_folder ".", "/vagrant"


  # ==========================================================
  # PROVISIONING
  # ==========================================================

  config.vm.provision "shell", inline: <<-SHELL

    set -e

    export DEBIAN_FRONTEND=noninteractive

    echo ""
    echo "================================================"
    echo " Updating Ubuntu"
    echo "================================================"

    apt-get update -y
    apt-get upgrade -y


    # ========================================================
    # BASIC / SYSTEM TOOLS
    # ========================================================

    echo ""
    echo "Installing basic tools..."

    apt-get install -y \
      curl \
      wget \
      git \
      vim \
      nano \
      unzip \
      zip \
      tar \
      gzip \
      tree \
      htop \
      btop \
      tmux \
      screen \
      jq \
      yq \
      net-tools \
      iputils-ping \
      dnsutils \
      traceroute \
      telnet \
      netcat-openbsd \
      lsof \
      tcpdump \
      nmap \
      rsync \
      openssh-client \
      openssh-server \
      ca-certificates \
      gnupg \
      lsb-release \
      apt-transport-https \
      software-properties-common \
      build-essential


    # ========================================================
    # AWS CLI
    # ========================================================

    echo ""
    echo "Installing AWS CLI..."

    if ! command -v aws >/dev/null 2>&1; then
      case "$(dpkg --print-architecture)" in
        amd64) aws_arch="x86_64" ;;
        arm64) aws_arch="aarch64" ;;
        *) echo "Unsupported architecture for AWS CLI: $(dpkg --print-architecture)" >&2; exit 1 ;;
      esac

      tmp_dir="$(mktemp -d)"
      curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${aws_arch}.zip" \
        -o "${tmp_dir}/awscliv2.zip"
      unzip -q "${tmp_dir}/awscliv2.zip" -d "${tmp_dir}"
      "${tmp_dir}/aws/install" --update
      rm -rf "${tmp_dir}"
    fi

    aws --version


    # ========================================================
    # PYTHON
    # ========================================================

    echo ""
    echo "Installing Python..."

    apt-get install -y \
      python3 \
      python3-pip \
      python3-venv \
      python3-dev


    # ========================================================
    # JAVA
    # ========================================================

    echo ""
    echo "Installing Java..."

    apt-get install -y \
      openjdk-17-jdk

    java -version


    # ========================================================
    # MAVEN
    # ========================================================

    echo ""
    echo "Installing Maven..."

    apt-get install -y maven

    mvn -version


    # ========================================================
    # DOCKER
    # ========================================================

    echo ""
    echo "Installing Docker..."

    install -m 0755 -d /etc/apt/keyrings

    curl -fsSL \
      https://download.docker.com/linux/ubuntu/gpg \
      -o /etc/apt/keyrings/docker.asc

    chmod a+r /etc/apt/keyrings/docker.asc

    echo \
      "deb [arch=$(dpkg --print-architecture) \
      signed-by=/etc/apt/keyrings/docker.asc] \
      https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
      > /etc/apt/sources.list.d/docker.list

    apt-get update -y

    apt-get install -y \
      docker-ce \
      docker-ce-cli \
      containerd.io \
      docker-buildx-plugin \
      docker-compose-plugin

    systemctl enable docker
    systemctl start docker

    # Allow vagrant user to run Docker without sudo
    usermod -aG docker vagrant

    docker --version
    docker compose version


    # ========================================================
    # TERRAFORM
    # ========================================================

    echo ""
    echo "Installing Terraform..."

    wget -O- https://apt.releases.hashicorp.com/gpg \
      | gpg --dearmor \
      > /usr/share/keyrings/hashicorp-archive-keyring.gpg

    chmod 644 /usr/share/keyrings/hashicorp-archive-keyring.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) \
      signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
      https://apt.releases.hashicorp.com \
      $(lsb_release -cs) main" \
      > /etc/apt/sources.list.d/hashicorp.list

    apt-get update -y

    apt-get install -y terraform

    terraform version


    # ========================================================
    # ANSIBLE
    # ========================================================

    echo ""
    echo "Installing Ansible..."

    apt-get install -y ansible

    ansible --version


    # ========================================================
    # KUBERNETES TOOLS
    # ========================================================

    echo ""
    echo "Installing Kubernetes tools..."

    mkdir -p -m 755 /etc/apt/keyrings

    curl -fsSL \
      https://pkgs.k8s.io/core:/stable:/v1.37/deb/Release.key \
      | gpg --dearmor \
      -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

    chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

    echo \
      'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
      https://pkgs.k8s.io/core:/stable:/v1.37/deb/ /' \
      > /etc/apt/sources.list.d/kubernetes.list

    apt-get update -y

    apt-get install -y kubectl

    apt-mark hold kubectl

    kubectl version --client


    # ========================================================
    # HELM
    # ========================================================

    echo ""
    echo "Installing Helm..."

    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
      | bash

    helm version


    # ========================================================
    # KUBECTX / KUBENS
    # ========================================================

    echo ""
    echo "Installing kubectx and kubens..."

    apt-get install -y kubectx


    # ========================================================
    # GIT CONFIGURATION
    # ========================================================

    echo ""
    echo "Configuring Git..."

    git config --system init.defaultBranch main


    # ========================================================
    # BASH ALIASES
    # ========================================================

    echo ""
    echo "Creating DevOps aliases..."

    cat >> /home/vagrant/.bashrc <<'EOF'

# ==========================================
# DevOps Lab Aliases
# ==========================================

alias ll='ls -lah'
alias la='ls -A'

alias k='kubectl'
alias kgp='kubectl get pods'
alias kgn='kubectl get nodes'
alias kgs='kubectl get svc'

alias tf='terraform'
alias d='docker'
alias dc='docker compose'

alias ports='sudo ss -tulpn'
alias myip='hostname -I'

EOF

    chown vagrant:vagrant /home/vagrant/.bashrc


    # ========================================================
    # SSH
    # ========================================================

    systemctl enable ssh
    systemctl start ssh


    # ========================================================
    # CLEANUP
    # ========================================================

    echo ""
    echo "Cleaning package cache..."

    apt-get autoremove -y
    apt-get clean


    # ========================================================
    # FINAL OUTPUT
    # ========================================================

    echo ""
    echo "================================================"
    echo " Ubuntu DevOps Lab Installation Complete"
    echo "================================================"

    echo ""
    echo "Installed tools:"
    echo "----------------"
    echo "Git"
    echo "Docker"
    echo "Docker Compose"
    echo "Terraform"
    echo "Ansible"
    echo "kubectl"
    echo "Helm"
    echo "Python3"
    echo "Java 17"
    echo "Maven"
    echo "Nmap"
    echo "tcpdump"
    echo "jq"
    echo "vim"
    echo "htop"
    echo "tmux"
    echo ""

  SHELL

end