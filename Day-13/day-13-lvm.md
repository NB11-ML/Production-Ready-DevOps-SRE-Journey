# 🐧 Day 13 – Linux Volume Management (LVM)

## Task
Learn LVM to manage storage flexibly – create, extend, and mount volumes.


## Challenge Tasks

### Task 1: Check Current Storage
Run: `lsblk`, `pvs`, `vgs`, `lvs`, `df -h`

<img width="837" height="602" alt="image" src="https://github.com/user-attachments/assets/c3d98d60-6823-4407-8e38-ccb075012a77" />


### Task 2: Create Physical Volume
```bash
pvcreate /dev/sdb   # or your loop device
pvs
```
<img width="576" height="287" alt="image" src="https://github.com/user-attachments/assets/fcd32501-9682-4766-8aff-1a2edb61ac50" />


### Task 3: Create Volume Group
```bash
vgcreate devops-vg /dev/sdb
vgs
```

<img width="610" height="278" alt="image" src="https://github.com/user-attachments/assets/64854d7e-076b-476f-ae59-be273fcdb366" />


### Task 4: Create Logical Volume
```bash
lvcreate -L 500M -n app-data devops-vg
lvs
```

<img width="897" height="290" alt="image" src="https://github.com/user-attachments/assets/f5706f06-da7c-402b-88f9-2c6bdf2be11f" />


### Task 5: Format and Mount
```bash
mkfs.ext4 /dev/devops-vg/app-data
mkdir -p /mnt/app-data
mount /dev/devops-vg/app-data /mnt/app-data
df -h /mnt/app-data
```

<img width="1058" height="727" alt="image" src="https://github.com/user-attachments/assets/61f82feb-ca84-4a53-b146-51ce9ac3d8bd" />


### Task 6: Extend the Volume
```bash
lvextend -L +200M /dev/devops-vg/app-data
resize2fs /dev/devops-vg/app-data
df -h /mnt/app-data
```

<img width="1078" height="542" alt="image" src="https://github.com/user-attachments/assets/bb1c5754-6832-41f4-8aef-a2daa1cda80f" />

---
