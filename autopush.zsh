#!/bin/zsh

#this script take url as input and push all the content to  origin (Github)
set -u

print_error() {
    echo "\n[ERROR] $1\n"
}

print_info() {
    echo "\n[INFO] $1\n"
}

run_with_retry() {
    local cmd="$1"
    local exit_code

    while true; do
        print_info "Running: $cmd"
        eval "$cmd"
        exit_code=$?

        if [[ $exit_code -eq 0 ]]; then
            return 0
        else
            print_error "Command failed."

            echo "Enter a command to resolve the issue:"
            read fixcmd

            if [[ -n "$fixcmd" ]]; then
                print_info "Running fix command: $fixcmd"
                eval "$fixcmd"
            fi

            echo "Retrying original command..."
        fi
    done
}



if [[ ! -d ".git" ]]; then
    print_info "Initializing git repository..."
    run_with_retry "git init"
else
    print_info "Git repository already initialized."
fi



echo "Enter origin repository URL:"
read origin_url

if [[ -z "$origin_url" ]]; then
    print_error "Origin URL cannot be empty."
    exit 1
fi

if git remote | grep -q origin; then
    print_info "Origin already exists. Updating URL."
    run_with_retry "git remote set-url origin $origin_url"
else
    run_with_retry "git remote add origin $origin_url"
fi


run_with_retry "git add ."


echo "Enter commit message:"
read commit_msg

if [[ -z "$commit_msg" ]]; then
    commit_msg="Auto commit"
fi

run_with_retry "git commit -m \"$commit_msg\""




branch=$(git branch --show-current 2>/dev/null)

if [[ -z "$branch" ]]; then
    branch="main"
    print_info "No branch detected. Creating branch $branch"
    run_with_retry "git checkout -b $branch"
fi



while true; do
    print_info "Pushing to origin..."

    git push -u origin "$branch"
    status=$?

    if [[ $status -eq 0 ]]; then
        echo "\n=============================="
        echo "Push to origin successful"
        echo "=============================="
        exit 0
    else
        print_error "Push failed."

        echo "Enter command to resolve the issue:"
        read fixcmd

        if [[ -n "$fixcmd" ]]; then
            print_info "Running fix command: $fixcmd"
            eval "$fixcmd"
        fi

        echo "Retrying push..."
    fi
done
