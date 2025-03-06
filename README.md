# Bare-Automation Script

## Overview
This Bash script, `bare-automation`, automates the setup of a deployment environment by performing the following tasks:
1. **User Configuration**: Creates a user (if not existing) and configures SSH access.
2. **Git Repository Setup**: Initializes a bare Git repository with a post-receive hook to automate deployment.
3. **Dependency Check**: Ensures required commands (`git`, `ssh-keygen`) are available before proceeding.

## How It Works
When executed, the script prompts the user for:
- **Username** (default: `deploy`)
- **Repository Name** (default: `app`)
- **Project Name** (default: `myApp`)
- **Environment** (default: `stg`)
- **Installation Directory** (default: `/opt/`)

After gathering this information, it logs the details and proceeds with the setup process.

### 1. Dependency Check
Before proceeding, the script verifies that `git` and `ssh-keygen` are installed. If any are missing, it logs an error and exits.

### 2. User Creation & SSH Configuration
- Checks if the specified user exists; if not, it creates the user and adds them to the `docker` group.
- Ensures the `.ssh` directory exists and has proper permissions.
- Generates an SSH key for the user if none exists.
- Sets up SSH key authentication.

### 3. Git Repository Setup
- Creates the necessary directory structure for the project.
- Initializes a bare Git repository (`*.git`).
- Configures a `post-receive` hook to automatically checkout files and restart Docker Compose upon receiving new code.

## Installation & Usage
### Running the Script
1. Save the script as `bare-automation.sh`.
2. Make it executable:
   ```bash
   chmod +x bare-automation.sh
   ```
3. Run the script:
   ```bash
   ./bare-automation.sh
   ```
4. Follow the prompts to enter details or accept the defaults.

### Log File
The script logs its operations in `/var/log/<username>_setup.log`, allowing easy debugging and tracking.

## Requirements
- Bash (Linux/macOS)
- `git`
- `ssh-keygen`
- Sudo privileges (for user creation and directory permissions)

## Notes
- Ensure the script is run with sufficient privileges to create users and manage directories.
- The `post-receive` hook assumes `docker compose restart` is a valid command in the deployment environment.

## License
This script is provided "as is" without warranty of any kind. Modify and use it as needed.

