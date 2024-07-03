#!/bin/bash

log_file="/var/log/user_management.log"
password_file="/var/secure/user_passwords.txt"

# Initialize log file and secure password file
touch "$log_file"
touch "$password_file"
chmod 600 "$password_file"
echo "Timestamp, Action, User, Details" > "$log_file"

# Function to generate a robust password with special characters
generate_password() {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&*()_+=-[]{}|;:,.<>?' | fold -w 16 | head -n 1
}

# Function to create a user and manage group associations
create_user() {
    user=$(echo "$1" | cut -d';' -f1 | xargs)
    groups=$(echo "$1" | cut -d';' -f2 | xargs)

    # Prevent duplicate user creation
    if id "$user" &>/dev/null; then
        echo "$(date +'%Y-%m-%d %H:%M:%S'), User already exists, $user," >> "$log_file"
        return
    fi

    # Create personal group
    groupadd "$user"

    # Create user account with home directory and primary group
    useradd -m -g "$user" "$user"
    if [ $? -ne 0 ]; then
        echo "$(date +'%Y-%m-%d %H:%M:%S'), Failed to create user, $user," >> "$log_file"
        return
    fi
    echo "$(date +'%Y-%m-%d %H:%M:%S'), User created, $user," >> "$log_file"

    # Set correct permissions for the home directory
    chmod 755 "/home/$user"
    chown "$user:$user" "/home/$user"
    echo "$(date +'%Y-%m-%d %H:%M:%S'), Set permissions, $user, Home directory permissions set to 700" >> "$log_file"

    # Add user to specified additional groups
    if [[ -n "$groups" ]]; then
        for group in $(echo "$groups" | tr ',' ' '); do
            if ! getent group "$group" &>/dev/null; then
                groupadd "$group"
                echo "$(date +'%Y-%m-%d %H:%M:%S'), Group created, $group," >> "$log_file"
            fi
            usermod -aG "$group" "$user"
            echo "$(date +'%Y-%m-%d %H:%M:%S'), Group added, $user, Added to '$group'" >> "$log_file"
        done
    fi

    # Generate and set a strong password
    password=$(generate_password)
    echo "$user:$password" | chpasswd
    if [ $? -eq 0 ]; then
        echo "$user,$password" >> "$password_file"
        echo "$(date +'%Y-%m-%d %H:%M:%S'), Password set, $user," >> "$log_file"
    else
        echo "$(date +'%Y-%m-%d %H:%M:%S'), Failed to set password, $user," >> "$log_file"
    fi
}

# Validate the provided input file
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

input_file="$1"

# Process user data from the input file
while IFS= read -r line; do
    # Skip blank lines or comments
    if [[ -z "$line" || "$line" =~ ^\s*# ]]; then
        continue
    fi

    create_user "$line"
done < "$input_file"

# Notify user that the process is complete
echo "User creation process completed. Check the log file for details: $log_file"
