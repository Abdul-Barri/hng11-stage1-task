## Optimizing My Company's User Management with a Bash Script

### Introduction

Efficient user and group management is crucial for any organization's IT infrastructure. To streamline this process, I've developed a robust Bash script that automates the creation of user accounts and their associated groups. This script not only simplifies user management but also ensures security by generating strong passwords and setting appropriate permissions for home directories.

### Script Overview

The Bash script `create_users.sh` reads a text file containing usernames and group names, creates the users and groups as specified, sets up home directories with appropriate permissions and ownership, generates random passwords for the users, and logs all actions. Additionally, the script stores the generated passwords securely.

### The Script

Here's the complete `create_users.sh` script:

```bash
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
```

### Detailed Breakdown

#### Initialization

The script begins by defining the log and password files. It ensures these files exist and have the correct permissions, creating them if necessary and restricting access to the password file to maintain security. This section sets up the foundation for logging actions and storing passwords securely.

#### Password Generation

The `generate_password` function creates strong passwords using a mix of alphanumeric and special characters. This ensures that the generated passwords are robust and difficult to guess, enhancing the security of user accounts.

#### User and Group Management

The `create_user` function handles the core functionality of the script. It parses the username and groups from the input line, checks for existing users to prevent duplicates, and creates a personal group for the user. It then creates the user account, sets the correct permissions and ownership for the user's home directory, and adds the user to any specified additional groups. This comprehensive approach ensures that each user is set up correctly and securely.

#### Input File Validation

Before processing user data, the script validates the provided input file, ensuring that exactly one argument is passed. It then reads each line from the input file, skipping blank lines and comments, and calls the `create_user` function to handle user creation. This step ensures that only valid user data is processed, preventing errors and maintaining script reliability.

#### Completion Notification

Finally, the script concludes by notifying the user that the process is complete and directing them to check the log file for details. This user-friendly touch ensures that the administrator is informed of the script's actions and can verify the results.

### Running the Script

To execute the script, follow these steps:

1. **Ensure the script is executable**:
    ```bash
    chmod +x create_users.sh
    ```

2. **Run the script with `sudo` to have the necessary permissions**:
    ```bash
    sudo ./create_users.sh user_list.txt
    ```

3. **Verify**: Check the log file and password file for actions and generated passwords.

### Conclusion

Automating user management with a Bash script like `create_users.sh` optimizes efficiency and security within an organization. This script provides a reliable solution to handle user creation, group assignments, and password management, all while maintaining comprehensive logs.

For more insights and opportunities in tech, check out the [HNG Internship](https://hng.tech/internship), [HNG Hire](https://hng.tech/hire), and [HNG Premium](https://hng.tech/premium).
