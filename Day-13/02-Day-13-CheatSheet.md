# Day 13 – Cheat Sheet: Linux Logical Volume Management (LVM)

A quick-reference guide for LVM structural architectures and command workflows [1].

## 🛠️ LVM Storage Abstraction Architecture
LVM provides flexible abstraction between raw disks and filesystems:
`Physical Volumes (PVs)` -> `Volume Groups (VGs)` -> `Logical Volumes (LVs)` -> `Filesystem`

## 🔍 Core Command Matrix
*   **Inspection:** `lsblk`, `pvs`, `vgs`, `lvs`, `df -h`
*   **Creation:** `pvcreate`, `vgcreate`, `lvcreate`
*   **Expansion:** `lvextend`, `resize2fs`

## 🚨 Production SRE Runbooks

### 1. Provisioning Storage
```bash
sudo pvcreate /dev/nvme1n1 /dev/nvme2n1
sudo vgcreate nb11_vg /dev/nvme1n1 /dev/nvme2n1
sudo lvcreate -L 10G -n nb11_lv nb11_vg
sudo mkfs.ext4 /dev/nb11_vg/nb11_lv
sudo mount /dev/nb11_vg/nb11_lv /mnt/app-data
```

### 2. Online Scaling (Hot-grow)
```bash
sudo lvextend -L +1G /dev/nb11_vg/nb11_lv
sudo resize2fs /dev/nb11_vg/nb11_lv
```

## 🕵️ Emergency Triage
*   **VG Full:** Add disks via `pvcreate` and `vgextend`.
*   **Persistence:** Ensure entries in `/etc/fstab` use `/dev/mapper/` paths.
