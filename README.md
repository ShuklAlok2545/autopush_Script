# Auto Git Push Script

A **Zsh-based automation script** that simplifies pushing a local project to a remote Git repository. The script performs all essential repository setup tasks automatically and includes **robust error handling with retry logic** for common Git issues.

The script is designed for developers who want a **single command workflow** to initialize a repository, configure Git settings, stage changes, commit, and push to a remote repository.

This project uses **Git** and is intended to run in the **Zsh shell** environment.

---

# Features

* Automatic **Git repository initialization**
* Automatic **Git user configuration**
* Detects and configures **remote origin**
* Stages all project files
* Creates commits with user-provided messages
* Automatically detects or creates a branch
* Pushes to remote repository
* Handles common Git errors
* Provides retry options when commands fail
* Detects invalid remote URLs and prompts for correction

---

# Requirements

Before running the script, ensure the following are installed:

* **Git**
* **Zsh shell**

Verify Git installation:

```bash
git --version
```

---

# Installation

1. Clone the repository or download the script.
2. Make the script executable.

```bash
chmod +x autopush.zsh
```

3. Run the script.

```bash
./autopush.zsh
```

---

# Workflow

When executed, the script performs the following steps:

## 1. Check Git Installation

The script verifies that Git is installed on the system.
If Git is not found, execution stops and the user is prompted to install it.

---

## 2. Initialize Repository

The script checks whether the current directory is already a Git repository.

* If `.git` does not exist → `git init` is executed.
* If it exists → the script continues using the existing repository.

---

## 3. Configure Git User

The script checks if the following Git configuration values exist:

* `user.name`
* `user.email`

If they are missing, the script prompts the user to enter them and saves them using:

```bash
git config user.name
git config user.email
```

---

## 4. Configure Remote Repository

The script checks if a remote repository named **origin** already exists.

### Case 1 – Origin Exists

* The existing URL is displayed.
* The script attempts to verify the connection using:

```bash
git fetch origin
```

### Case 2 – Origin Does Not Exist

The user is prompted to enter a Git repository URL.

Example:

```bash
https://github.com/username/project.git
```

The script then adds it using:

```bash
git remote add origin <repository-url>
```

---

## 5. Stage Files

All files in the current directory are added to Git staging using:

```bash
git add .
```

---

## 6. Detect Changes

Before committing, the script checks whether there are staged changes.

* If no changes exist → the script skips committing.
* If changes exist → the script asks for a commit message.

---

## 7. Create Commit

If changes are present, a commit is created using:

```bash
git commit -m "commit message"
```

If no message is provided, the script automatically uses:

```
Auto commit
```

---

## 8. Detect or Create Branch

The script checks the current Git branch.

If no branch exists, it automatically creates the **main** branch:

```bash
git checkout -b main
```

---

## 9. Verify Remote Branch

The script checks whether the branch exists on the remote repository.

If the branch does not exist, it will be created during the push operation.

---

## 10. Push to Remote Repository

The script attempts to push changes to the remote repository using:

```bash
git push -u origin <branch>
```

The `-u` flag sets the upstream tracking branch.

---

# Error Handling and Retry System

The script includes a retry mechanism that automatically detects and handles common Git errors.

## Invalid Repository URL

If Git returns an error such as:

```
Repository not found
```

The script will:

1. Remove the existing remote origin
2. Ask the user for a correct repository URL
3. Reattach the new remote repository
4. Retry the failed command

---

## Command Failure

If any Git command fails for reasons other than repository errors:

* The error message is displayed.
* The user is prompted to enter a command to resolve the issue.
* The original command is retried after the fix.

Example fixes:

```
git pull origin main --rebase
git config --global credential.helper store
```

---

# Example Execution Flow

```
[INFO] Git repository already initialized.
[INFO] Origin already exists.
[INFO] Using existing remote: https://github.com/user/project.git

[INFO] Adding files...
[INFO] Running: git add .

Enter commit message:
Initial commit

[INFO] Running: git commit -m "Initial commit"

[INFO] Pushing to origin...

[SUCCESS] Push to origin successful
```

---

# Advantages

* Automates repetitive Git workflows
* Reduces manual command execution
* Provides clear error messages
* Includes automatic recovery from common Git mistakes
* Suitable for beginners and automation scripts

---

