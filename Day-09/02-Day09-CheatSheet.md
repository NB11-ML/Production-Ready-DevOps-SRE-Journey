
# 🐧📃 Day 09 - Linux User & Group Management Cheat Sheet

## Core Commands & Options

**User Management:**

*   `useradd [OPTIONS] username`: Creates a new user account.
    *   `-m`: Create home directory for the user.
    *   `-s /bin/bash` (Example): Specify login shell.
*   `passwd username`: Changes or sets password for a user (interactive).  *Don't include passwords in cheat sheets! This shows the process, not revealing credentials.*
*   `usermod [OPTIONS] username`: Modifies an existing user account.
    *   `-aG group1,group2`: Add user to groups `group1` and `group2`.  (Important: `-a` is for *append*, don't overwrite existing group memberships)
*   `userdel username`: Deletes a user account (use with caution!).

**Group Management:**

*   `groupadd groupname`: Creates a new group.
*   `groupmod [OPTIONS] groupname`: Modifies an existing group. (Less commonly used directly).
*   `groupdel groupname`: Removes a group (use with caution!).

**Permissions & Ownership:**

*   `chown user:group file/directory`: Changes ownership of a file or directory.  (e.g., `sudo chown tokyo:developers my_file.txt`)
*   `chgrp group file/directory`: Changes the group ownership of a file or directory. (e.g. `sudo chgrp developers /opt/dev-project`)
*   `chmod [mode] file/directory`: Changes permissions.
    *   **Octal Notation:**  (Most common for direct control)
        *   `777`: Read, write, and execute for everyone. (Generally avoid!)
        *   `775`: Read, write, and execute for owner and group; read and execute for others.
        *   `755`: Read, write, and execute for owner; read and execute for group and others.
        *  `644`: Read and write for Owner, Read only for Group and Others
    *   **Symbolic Notation:** (More readable but less precise) - e.g., `chmod u+w file` (Add write permission for the user).

**Verification & Information:**

*   `cat /etc/passwd`: Displays user account information.  Use `grep username` to find a specific user.
*   `cat /etc/group`:  Displays group information. Use `grep groupname` to find a specific group.
*   `groups username`: Shows the groups a user belongs to.
*   `ls -l file/directory`: Lists files and directories with detailed permissions, owner, and group. Includes readable permission representation like `-rwxr-xr-x`.

## Common Use Cases / Scenarios

**1. Creating a User:**

```bash
sudo useradd -m newuser
sudo passwd newuser
```

**2. Adding a User to Groups:**

```bash
sudo usermod -aG developers,admins existinguser
```

**3. Changing File Permissions (Example: Make /opt/shared_file writable by the group):**

```bash
sudo chgrp sharedgroup /opt/shared_file
sudo chmod 664 /opt/shared_file  #OR sudo chmod g+w /opt/shared_file (Symbolic notation)
```

**4. Running a Command as Another User:**

```bash
sudo -u tokyo ls -l /home/berlin  # Lists the contents of Berlin's home directory, acting as user Tokyo.
```

## Key Reminders & Best Practices

*   **`-m` flag with `useradd`**: Always use this flag if you want a home directory for the new user.
*   **`-aG` for adding groups:** Use `-a` to *append* instead of overwriting group memberships with `usermod`.  Omitting -a will delete all group assignments!
*   **Testing is Crucial**: Always verify changes using commands like `groups`, `ls -l`, and by attempting operations as the affected user (`sudo -u`).
*   **Security Awareness:** Be extremely cautious when modifying permissions (especially with `chmod 777`). Minimize permissions to only what's absolutely necessary.

## Troubleshooting Tips

*   **"Permission denied":** Use `sudo` before commands requiring elevated privileges. Check file/directory ownership and permissions (`ls -ld`).
*   **User cannot access a directory:**  Verify the user is in the correct group(s) using `groups username`. Double-check the directory's group ownership and permissions (`ls -l`).
*   **Confused about Octal Notation?**: Use online resources to convert symbolic modes (e.g., "u+rw,g+r") to octal (e.g., 640) or vice versa.  Understanding how each digit represents owner, group, and other permissions is key.
