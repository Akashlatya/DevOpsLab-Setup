#!/usr/bin/env bash
###############################################################################
# devops-lab-setup.sh
#
# Purpose : Ek fresh-installed Ubuntu machine par DevOps lab ka pura setup
#           ek hi script se ho jaye — bina kisi manual step ke.
#
# Covers  : System update, Git, Docker + Docker Compose, Java (JDK),
#           Jenkins, Ansible, AWS CLI v2, kubectl, Terraform, Minikube
#
# Usage   : chmod +x devops-lab-setup.sh
#           ./devops-lab-setup.sh
#
# Notes   : - Script idempotent hai — dubara chalao to bhi error nahi aayega,
#             already-installed cheezein skip ho jayengi.
#           - Har step ke baad status print hota hai taaki pata chale kahan
#             tak setup hua.
#           - Docker group add hone ke baad ek baar logout/login ya
#             `newgrp docker` chalana padega.
###############################################################################

set -euo pipefail
IFS=$'\n\t'

LOG_FILE="$HOME/devops-lab-setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# ---------- Helper functions ----------
info()  { echo -e "\e[34m[INFO]\e[0m  $1"; }
ok()    { echo -e "\e[32m[OK]\e[0m    $1"; }
warn()  { echo -e "\e[33m[WARN]\e[0m  $1"; }
err()   { echo -e "\e[31m[ERROR]\e[0m $1"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

configure_jenkins_repo() {
    sudo install -d -m 0755 /etc/apt/keyrings
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | \
        sudo gpg --dearmor --yes -o /etc/apt/keyrings/jenkins-keyring.gpg
    sudo chmod a+r /etc/apt/keyrings/jenkins-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.gpg]" \
        "https://pkg.jenkins.io/debian-stable binary/" | \
        sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
}

trap 'err "Script line $LINENO par fail hua. Log dekho: $LOG_FILE"' ERR

if [[ $EUID -eq 0 ]]; then
    err "Is script ko root se mat chalao. Normal user se chalao (sudo internally use hoga)."
    exit 1
fi

info "DevOps lab setup shuru ho raha hai. Log yaha save ho raha hai: $LOG_FILE"

# Repair a Jenkins source left by an interrupted earlier run before apt update.
if [[ -f /etc/apt/sources.list.d/jenkins.list ]]; then
    configure_jenkins_repo
fi

# ---------- 1. System update ----------
info "Step 1: System update ho raha hai..."
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release software-properties-common apt-transport-https \
    unzip zip wget git build-essential vim nano htop net-tools tree jq tmux python3 python3-pip
ok "System update aur base packages (vim, unzip, wget, htop, jq, tree, etc.) ho gaye."

# ---------- 2. Git basic config ----------
info "Step 2: Git config check ho raha hai..."
if [[ -z "$(git config --global user.name 2>/dev/null || true)" ]]; then
    warn "Git username set nahi hai. Baad me manually set karo:"
    warn '  git config --global user.name "Your Name"'
    warn '  git config --global user.email "you@example.com"'
else
    ok "Git already configured: $(git config --global user.name)"
fi

# ---------- 3. VS Code ----------
info "Step 3: VS Code install ho raha hai..."
if command_exists code; then
    ok "VS Code already installed hai: $(code --version | head -n1)"
else
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
      sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

    sudo apt-get update -y
    sudo apt-get install -y code
    ok "VS Code install ho gaya: $(code --version | head -n1)"
fi

# ---------- 4. Docker ----------
info "Step 4: Docker install ho raha hai..."
if command_exists docker; then
    ok "Docker already installed hai: $(docker --version)"
else
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    ARCH="$(dpkg --print-architecture)"
    CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
    echo \
      "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    ok "Docker install ho gaya: $(docker --version)"
fi

if ! groups "$USER" | grep -q '\bdocker\b'; then
    sudo usermod -aG docker "$USER"
    warn "User '$USER' ko docker group me add kiya. Effect ke liye logout/login ya 'newgrp docker' chalao."
else
    ok "User already docker group me hai."
fi

sudo systemctl enable --now docker
ok "Docker service enabled aur running hai."

# ---------- 5. Java (Jenkins ke liye zaroori) ----------
info "Step 5: Java (JDK) install ho raha hai..."
if command_exists java; then
    ok "Java already installed hai: $(java -version 2>&1 | head -n1)"
else
    sudo apt-get install -y fontconfig openjdk-17-jre
    ok "Java install ho gaya: $(java -version 2>&1 | head -n1)"
fi

# ---------- 6. Jenkins ----------
info "Step 6: Jenkins install ho raha hai..."
if command_exists jenkins || systemctl list-unit-files 2>/dev/null | grep -q '^jenkins.service'; then
    ok "Jenkins already installed hai."
else
        configure_jenkins_repo

    sudo apt-get update -y
    sudo apt-get install -y jenkins
    sudo systemctl enable --now jenkins
    ok "Jenkins install ho gaya aur service start ho gayi (port 8080)."
fi

# ---------- 7. Ansible ----------
info "Step 7: Ansible install ho raha hai..."
if command_exists ansible; then
    ok "Ansible already installed hai: $(ansible --version | head -n1)"
else
    sudo apt-add-repository --yes --update ppa:ansible/ansible
    sudo apt-get install -y ansible
    ok "Ansible install ho gaya: $(ansible --version | head -n1)"
fi

# ---------- 8. AWS CLI v2 ----------
info "Step 8: AWS CLI v2 install ho raha hai..."
if command_exists aws; then
    ok "AWS CLI already installed hai: $(aws --version)"
else
    TMP_DIR="$(mktemp -d)"
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$TMP_DIR/awscliv2.zip"
    unzip -q "$TMP_DIR/awscliv2.zip" -d "$TMP_DIR"
    sudo "$TMP_DIR/aws/install"
    rm -rf "$TMP_DIR"
    ok "AWS CLI install ho gaya: $(aws --version)"
fi

# ---------- 9. kubectl ----------
info "Step 9: kubectl install ho raha hai..."
if command_exists kubectl; then
    ok "kubectl already installed hai: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
    KUBECTL_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
    curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
    rm -f /tmp/kubectl
    ok "kubectl install ho gaya: $(kubectl version --client 2>/dev/null || true)"
fi

# ---------- 10. Terraform ----------
info "Step 10: Terraform install ho raha hai..."
if command_exists terraform; then
    ok "Terraform already installed hai: $(terraform -version | head -n1)"
else
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${CODENAME} main" | \
      sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y terraform
    ok "Terraform install ho gaya: $(terraform -version | head -n1)"
fi

# ---------- 11. Minikube (optional local Kubernetes cluster) ----------
info "Step 11: Minikube install ho raha hai..."
if command_exists minikube; then
    ok "Minikube already installed hai: $(minikube version --short 2>/dev/null || true)"
else
    curl -fsSLo /tmp/minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install /tmp/minikube /usr/local/bin/minikube
    rm -f /tmp/minikube
    ok "Minikube install ho gaya."
fi

# ---------- Final Verification: version check for every tool ----------
echo
echo "==================== FINAL VERIFICATION ===================="
info "Har tool ka version check ho raha hai taaki confirm ho sake sab sahi install hua..."
echo

FAILED_TOOLS=()
set +e   # verification me kisi tool ke fail hone se pura script na ruke

check_version() {
    local name="$1"
    local cmd="$2"
    local output
    if output="$(eval "$cmd" 2>&1)"; then
        printf "  %-12s : \e[32m%s\e[0m\n" "$name" "$(echo "$output" | head -n1)"
    else
        printf "  %-12s : \e[31mNOT FOUND / FAILED\e[0m\n" "$name"
        FAILED_TOOLS+=("$name")
    fi
}

check_version "vim"       "vim --version"
check_version "wget"      "wget --version"
check_version "unzip"     "unzip -v"
check_version "jq"        "jq --version"
check_version "htop"      "htop --version"
check_version "tree"      "tree --version"
check_version "tmux"      "tmux -V"
check_version "git"       "git --version"
check_version "code"      "code --version"
check_version "docker"    "docker --version"
check_version "java"      "java -version"
check_version "jenkins"   "systemctl is-active jenkins && echo Jenkins service active"
check_version "ansible"   "ansible --version"
check_version "aws"       "aws --version"
check_version "kubectl"   "kubectl version --client"
check_version "terraform" "terraform -version"
check_version "minikube"  "minikube version"

echo "==============================================================="
echo
set -e

if [[ ${#FAILED_TOOLS[@]} -eq 0 ]]; then
    ok "Sab tools sahi se install ho gaye aur version check pass ho gaya! ✅"
else
    err "In tools me issue mila: ${FAILED_TOOLS[*]}"
    warn "Inhe manually check karo ya script dubara chalao — idempotent hai, safe hai."
fi

echo
warn "IMPORTANT: Docker group changes apply karne ke liye ek baar logout/login karo,"
warn "ya terminal me 'newgrp docker' chala kar naya group session lo."
warn "Jenkins initial admin password ke liye ye command chalao:"
warn "  sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
warn "Jenkins UI: http://localhost:8080"
ok "DevOps lab setup complete ho gaya! Poora log yaha hai: $LOG_FILE"
