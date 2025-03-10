#!/bin/bash

echo ""
read -p "Enter the username (default: deploy): " USER
USER="${USER:-deploy}"
read -p "Enter the repository name (default: app): " REPOSITORY
REPOSITORY="${REPOSITORY:-app}"
read -p "Enter the project name (default: myApp): " PROJECT_NAME
PROJECT_NAME="${PROJECT_NAME:-myApp}"
read -p "Enter the environment (default: stg): " ENVIRONMENT
ENVIRONMENT="${ENVIRONMENT:-stg}"
read -p "Enter the directory (default: /opt/): " PATH_DIR
PATH_DIR="${PATH_DIR:-/opt/}" && DIR="${PATH_DIR}/${PROJECT_NAME}/${ENVIRONMENT}/${REPOSITORY}"
LOG_FILE="/var/log/${USER}_setup.log"

echo ""
echo "Your resume info:"
echo "Username: $USER"
echo "Repository: $REPOSITORY"
echo "Project: $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo "Directory: $PATH_DIR"

function log() {
    local MESSAGE="$1"
    echo "$(date +'%Y-%m-%d %H:%M:%S') $MESSAGE" | tee -a "$LOG_FILE"
}

function check_dependencies() {
    for cmd in git ssh-keygen; do
        if ! command -v "$cmd" &> /dev/null; then
            echo ""
            log "[ERROR] Required command '$cmd' not found."
            exit 1
        fi
    done
}

function create_user() {
    echo ""
    log "***** Configuring User *****"

    if id "$USER" &>/dev/null; then
        log "[INFO] User '$USER' already exists."
    else
        log "[TASK] Creating user '$USER'"
        sudo useradd -m -s /bin/bash "$USER" && log "[SUCCESS] User '$USER' created."
        sudo usermod -aG docker "$USER"
    fi

    sudo mkdir -p "/home/$USER/.ssh"
    sudo chmod 700 "/home/$USER/.ssh"

    if [[ ! -f "/home/$USER/.ssh/id_rsa" ]]; then
        log "[TASK] Generating SSH key for '$USER'"
        sudo ssh-keygen -t rsa -b 4096 -f "/home/$USER/.ssh/id_rsa" -N "" -q && \
        sudo cp "/home/$USER/.ssh/id_rsa.pub" "/home/$USER/.ssh/authorized_keys" && \
        sudo chmod 600 "/home/$USER/.ssh/authorized_keys"
    else
        log "[INFO] SSH key already exists for '$USER'"
    fi

    sudo chown -R "$USER:$USER" "/home/$USER/.ssh"
    log "[SUCCESS] SSH configuration completed for '$USER'"
}

function configure_repository() {
    echo ""
    log "***** Configuring Git Repository *****"

    if [[ -d "$DIR" ]]; then
        log "[INFO] Directory '$DIR' already exists."
    else
        log "[TASK] Creating directory '$DIR'"
        sudo mkdir -p "$DIR"
        sudo chown -R "$USER:$USER" "$DIR"
    fi

    if [[ -d "$DIR.git" ]]; then
        log "[INFO] Repository '$DIR.git' already exists."
    else
        log "[TASK] Creating Git Bare repository at '$DIR.git'"
        sudo mkdir -p "$DIR.git"
        pushd "$DIR.git" > /dev/null
        sudo git init --bare > /dev/null
        # Post-receive content
        echo "#!/bin/bash" > $DIR.git/hooks/post-receive
        echo "git --work-tree=$DIR --git-dir=$DIR.git checkout -f" >> $DIR.git/hooks/post-receive
        echo "docker compose restart" >> $DIR.git/hooks/post-receive
        # Set permissions
        sudo chmod +x "$DIR.git/hooks/post-receive"
        sudo chown -R "$USER:$USER" "$DIR.git"
        popd > /dev/null
        log "[SUCCESS] Git repository created at '$DIR.git'"
    fi
    
    else
        log "[TASK] Creating Git Bare repository at '$DIR.git'"
        sudo mkdir -p "$DIR.git"
        pushd "$DIR.git" > /dev/null
        sudo git init --bare > /dev/null
        
        # Post-receive content
        echo "#!/bin/bash" > $DIR.git/hooks/post-receive
        echo "git --work-tree=$DIR --git-dir=$DIR.git checkout -f" >> $DIR.git/hooks/post-receive
        
        # Check docker service
        echo "if docker compose ls | grep -q ${PROJECT_NAME}; then" >> $DIR.git/hooks/post-receive
        echo "    docker compose restart" >> $DIR.git/hooks/post-receive
        echo "else" >> $DIR.git/hooks/post-receive
        echo "    cd /${PATH_DIR}/${PROJECT_NAME}/${ENVIRONMENT}" >> $DIR.git/hooks/post-receive
        echo "    docker compose up -d" >> $DIR.git/hooks/post-receive
        echo "fi" >> $DIR.git/hooks/post-receive

        # Set permissions
        sudo chmod +x "$DIR.git/hooks/post-receive"
        sudo chown -R "$USER:$USER" "$DIR.git"
        popd > /dev/null
        log "[SUCCESS] Git repository created at '$DIR.git'"
    fi
}

# Main execution flow
echo ""
log "Starting setup for user '$USER' and repository '$REPOSITORY'"

check_dependencies
create_user
configure_repository

log "Setup completed successfully."
