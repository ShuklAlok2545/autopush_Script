# #!/bin/zsh

# #this script take url as input and push all the content to  origin (Github)
# set -u

# print_error() {
#     echo "\n[ERROR] $1\n"
# }

# print_info() {
#     echo "\n[INFO] $1\n"
# }

# run_with_retry() {
#     local cmd="$1"
#     local exit_code

#     while true; do
#         print_info "Running: $cmd"
#         eval "$cmd"
#         exit_code=$?

#         if [[ $exit_code -eq 0 ]]; then
#             return 0
#         else
#             print_error "Command failed."

#             echo "Enter a command to resolve the issue:"
#             read fixcmd

#             if [[ -n "$fixcmd" ]]; then
#                 print_info "Running fix command: $fixcmd"
#                 eval "$fixcmd"
#             fi

#             echo "Retrying original command..."
#         fi
#     done
# }



# if [[ ! -d ".git" ]]; then
#     print_info "Initializing git repository..."
#     run_with_retry "git init"
# else
#     print_info "Git repository already initialized."
# fi



# echo "Enter origin repository URL:"
# read origin_url

# if [[ -z "$origin_url" ]]; then
#     print_error "Origin URL cannot be empty."
#     exit 1
# fi

# if git remote | grep -q origin; then
#     print_info "Origin already exists. Updating URL."
#     run_with_retry "git remote set-url origin $origin_url"
# else
#     run_with_retry "git remote add origin $origin_url"
# fi


# run_with_retry "git add ."


# echo "Enter commit message:"
# read commit_msg

# if [[ -z "$commit_msg" ]]; then
#     commit_msg="Auto commit"
# fi

# run_with_retry "git commit -m \"$commit_msg\""




# branch=$(git branch --show-current 2>/dev/null)

# if [[ -z "$branch" ]]; then
#     branch="main"
#     print_info "No branch detected. Creating branch $branch"
#     run_with_retry "git checkout -b $branch"
# fi



# while true; do
#     print_info "Pushing to origin..."

#     git push -u origin "$branch"
#     status=$?

#     if [[ $status -eq 0 ]]; then
#         echo "\n=============================="
#         echo "Push to origin successful"
#         echo "=============================="
#         exit 0
#     else
#         print_error "Push failed."

#         echo "Enter command to resolve the issue:"
#         read fixcmd

#         if [[ -n "$fixcmd" ]]; then
#             print_info "Running fix command: $fixcmd"
#             eval "$fixcmd"
#         fi

#         echo "Retrying push..."
#     fi
# done
#!/bin/zsh

set -u

# -----------------------------
# Logging helpers
# -----------------------------

info() {
  echo "\n[INFO] $1"
}

error() {
  echo "\n[ERROR] $1"
}

success() {
  echo "\n[SUCCESS] $1"
}

# -----------------------------
# Retry command wrapper
# -----------------------------
run_with_retry() {
    local cmd="$1"
    local output
    local exit_code

    while true; do
        print_info "Running: $cmd"

        output=$(eval "$cmd" 2>&1)
        exit_code=$?

        if [[ $exit_code -eq 0 ]]; then
            [[ -n "$output" ]] && echo "$output"
            return 0
        else
            echo "$output"

            # Detect repository URL errors
            if echo "$output" | grep -E "repository .* not found|Repository not found"; then

                print_error "Remote repository not found."

                if git remote | grep -q origin; then
                    print_info "Removing wrong origin..."
                    git remote remove origin
                fi

                echo "Enter correct GitHub repository URL:"
                read newurl

                if [[ -z "$newurl" ]]; then
                    print_error "URL cannot be empty."
                    continue
                fi

                print_info "Adding new origin..."
                git remote add origin "$newurl"

                continue
            fi

            print_error "Command failed."

            echo "Enter a command to fix the issue (or press Enter to retry):"
            read fixcmd

            if [[ -n "$fixcmd" ]]; then
                print_info "Running fix command: $fixcmd"
                eval "$fixcmd"
            fi

            echo "Retrying..."
        fi
    done
}

# -----------------------------
# Check Git installation
# -----------------------------

if ! command -v git >/dev/null 2>&1; then
  error "Git is not installed."
  echo "Install Git first."
  exit 1
fi

# -----------------------------
# Initialize repository
# -----------------------------

if [[ ! -d ".git" ]]; then
  info "Initializing git repository..."
  run_with_retry "git init"
else
  info "Git repository already initialized."
fi

# -----------------------------
# Configure Git user if missing
# -----------------------------

git_user=$(git config user.name || true)
git_email=$(git config user.email || true)

if [[ -z "$git_user" ]]; then
  echo "Enter Git user.name:"
  read user_name
  run_with_retry "git config user.name \"$user_name\""
fi

if [[ -z "$git_email" ]]; then
  echo "Enter Git user.email:"
  read user_email
  run_with_retry "git config user.email \"$user_email\""
fi

# -----------------------------
# Handle remote origin
# -----------------------------

if git remote get-url origin >/dev/null 2>&1; then

  origin_url=$(git remote get-url origin)
  info "Origin already exists."
  info "Using existing remote: $origin_url"

  run_with_retry "git fetch origin"

else

  echo "Enter GitHub repository URL:"
  read origin_url

  if [[ -z "$origin_url" ]]; then
    error "Origin URL cannot be empty."
    exit 1
  fi

  run_with_retry "git remote add origin $origin_url"

fi

# -----------------------------
# Stage files
# -----------------------------

info "Adding files..."

run_with_retry "git add ."

# -----------------------------
# Check if there are changes
# -----------------------------

if git diff --cached --quiet; then
  info "No changes to commit."
else

  echo "Enter commit message:"
  read commit_msg

  if [[ -z "$commit_msg" ]]; then
    commit_msg="Auto commit"
  fi

  run_with_retry "git commit -m \"$commit_msg\""

fi

# -----------------------------
# Detect branch
# -----------------------------

branch=$(git branch --show-current 2>/dev/null)

if [[ -z "$branch" ]]; then

  branch="main"

  info "Creating branch: $branch"
  run_with_retry "git checkout -b $branch"

fi

# -----------------------------
# Ensure upstream branch exists
# -----------------------------

if ! git ls-remote --heads origin "$branch" >/dev/null 2>&1; then
  info "Remote branch does not exist. Will create it."
fi

# -----------------------------
# Push loop
# -----------------------------
while true; do
    print_info "Pushing to origin..."

    push_output=$(git push -u origin "$branch" 2>&1)
    status=$?

    if [[ $status -eq 0 ]]; then
        echo "$push_output"
        echo "\n=============================="
        echo "Push to origin successful"
        echo "=============================="
        exit 0
    else
        print_error "Push failed:"
        echo "$push_output"

        # Detect repository or URL related errors
        if echo "$push_output" | grep -E "repository .* not found|Repository not found|not found"; then

            print_error "Remote repository URL appears invalid."

            if git remote | grep -q origin; then
                print_info "Removing existing origin remote..."
                git remote remove origin
            fi

            echo "Enter NEW origin repository URL:"
            read new_url

            if [[ -z "$new_url" ]]; then
                print_error "URL cannot be empty."
                continue
            fi

            print_info "Adding new origin remote..."
            git remote add origin "$new_url"

        else
            echo "\nEnter command to resolve the issue (or press Enter to retry):"
            read fixcmd

            if [[ -n "$fixcmd" ]]; then
                print_info "Running fix command: $fixcmd"
                eval "$fixcmd"
            fi
        fi

        echo "Retrying push..."
    fi
done
