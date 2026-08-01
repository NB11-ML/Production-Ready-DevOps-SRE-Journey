# 🐧 Day 09 – Linux User & Group Management Challenge

## Users & Groups Created

*   **Users:** tokyo, berlin, professor, nairobi
*   **Groups:** developers, admins, project-team

## Group Assignments

*   **tokyo:** developers
*   **berlin:** developers, admins
*   **professor:** admins
*   **nairobi:** project-team, developers (via assignment of tokyo)

## Directories Created

*   **/opt/dev-project**:  Group owner: developers, Permissions: 775
*   **/opt/team-workspace**: Group owner: project-team, Permissions: 775

## Challenge Tasks & Commands Used

### Task 1: Create Users (20 minutes)

```bash
sudo useradd -m tokyo
sudo passwd tokyo  # Set password interactively
sudo useradd -m berlin
sudo passwd berlin # Set password interactively
sudo useradd -m professor
sudo passwd professor # Set password interactively
```

Verification:

*   `cat /etc/passwd | grep tokyo` - Confirms user creation and home directory.
*   `ls -l /home`  - Verifies the existence of home directories (tokyo, berlin, professor).

      <img width="724" height="240" alt="Day_09_user_creation_verification" src="https://github.com/user-attachments/assets/3445184c-4afb-4bd8-aa45-9a27482e5414" />


### Task 2: Create Groups (10 minutes)

```bash
sudo groupadd developers
sudo groupadd admins
```

Verification:

*   `cat /etc/group | grep developers`
*   `cat /etc/group | grep admins`

      <img width="792" height="221" alt="Day_09_group_creation_verification" src="https://github.com/user-attachments/assets/0aef53e8-35ba-4bb0-b806-fdac489b3b7e" />


### Task 3: Assign to Groups (15 minutes)

```bash
sudo usermod -aG developers tokyo
sudo usermod -aG developers,admins berlin
sudo usermod -aG admins professor
```

Verification:

*   `groups tokyo` - Shows group membership for 'tokyo'
*   `groups berlin`  - Shows group membership for 'berlin'
*   `groups professor`- Shows group membership for 'professor'

      <img width="855" height="99" alt="Day_09_group_assignment_verification png " src="https://github.com/user-attachments/assets/539720eb-3764-4642-ae9f-45aa1f273708" />



### Task 4: Shared Directory (20 minutes)

```bash
sudo mkdir /opt/dev-project
sudo chgrp developers /opt/dev-project
sudo chmod 775 /opt/dev-project
```

Testing:

*   **As tokyo:** `sudo -u tokyo touch /opt/dev-project/tokyo_test.txt` -  Should succeed without permission errors.
*   **As berlin:** `sudo -u berlin touch /opt/dev-project/berlin_test.txt` - Should also succeed.

Verification:

*   `ls -ld /opt/dev-project` – Shows permissions, group ownership.



### Task 5: Team Workspace (20 minutes)

```bash
sudo useradd -m nairobi
sudo passwd nairobi #Set password interactively
sudo groupadd project-team
sudo usermod -aG project-team nairobi
sudo usermod -aG project-team tokyo
sudo mkdir /opt/team-workspace
sudo chgrp project-team /opt/team-workspace
sudo chmod 775 /opt/team-workspace
```

Testing:

*   **As nairobi:** `sudo -u nairobi touch /opt/team-workspace/nairobi_test.txt` - Should succeed without permission errors.


Verification:

*   `ls -ld /opt/team-workspace` – Shows permissions and group ownership.
*   `groups nairobi` – Confirms group memberships

      <img width="759" height="173" alt="Day_09_team_workspace_verification" src="https://github.com/user-attachments/assets/3eacb98c-ad17-4735-ba31-3ccb16001583" />


## Commands Used

*   `useradd`: Creates a new user account.
*   `passwd`: Changes or sets the password for a user account.
*   `usermod`: Modifies an existing user account (used for group assignments).
*   `groupadd`: Creates a new group.
*   `chgrp`: Changes the group ownership of a file or directory.
*   `chmod`: Changes the permissions of a file or directory.
*   `mkdir`: Creates a new directory.
*   `groups`: Displays the groups to which a user belongs.
*   `cat`: Displays the contents of a file (used for verification).
*   `ls -l`: Lists files and directories with detailed information, including permissions.
*   `sudo -u`: Executes a command as another user.

## What I Learned

*   **User Creation:**  The `useradd -m` flag is crucial to create the home directory automatically.
*   **Group Assignment Flexibility:** Users can be members of multiple groups simultaneously using commas in the `usermod -aG` options.
*   **Shared Permissions Management:** Using `chgrp` and `chmod` efficiently controls access rights for group-owned directories.
*   **Testing User Actions**: `sudo -u username command` is a really useful way to test permissions from another user's perspective.
