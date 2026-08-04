# 🐧 Day 13: Linux Logical Volume Management (LVM)

Welcome to Day 13 of the Production-Ready DevOps & SRE Journey! Today's focus is mastering **Logical Volume Management (LVM)**, a fundamental storage engineering capability required to manage, scale, and triage system storage dynamically in live production environments without causing system downtime.

---

## 📁 Repository Directory Structure

This folder contains the complete conceptual labs, practical code syntax execution tracks, and consolidated troubleshooting runbooks for this module:

*   **[`01-Day-13-lvm.md`](01-Day-13-lvm.md)**: The core lab documentation outlining hands-on storage infrastructure creation, formatting maps, and live filesystem partition adjustments.
*   **[`02-Day-13-CheatSheet.md`](02-Day-13-CheatSheet.md)**: A high-utility, production-focused operational cheat sheet mapping out LVM abstraction layers, command reference matrices, and emergency triage runbooks.

---

## 🎯 Lab Objectives & Challenge Tasks

During this lab, the following core storage milestones were successfully implemented and verified:
1. **Storage Topology Auditing**: Inspected raw blocks and directory limits using `lsblk`, `pvs`, `vgs`, `lvs`, and `df -h`.
2. **Physical Volume Initialization**: Created and pooled raw backend infrastructure hardware layers using `pvcreate`.
3. **Volume Group Pooling**: Grouped active physical allocations into a central scaling engine pool via `vgcreate`.
4. **Logical Partitioning**: Allocated structured workspace paths using `lvcreate` to segment pool space efficiently.
5. **Filesystem Integration**: Built EXT4 file tables using `mkfs.ext4` and dynamically bound them to `/mnt/app-data`.
6. **Live Volume Scaling**: Demonstrated online capacity adjustments under disk strain utilizing `lvextend` and `resize2fs` hot-growth pipelines without service interruptions.

---

## 🕵️ Quick-Reference Triage Commands

```bash
# Verify active storage layers at a glance
sudo pvs && sudo vgs && sudo lvs

# Scan for disk pressures or storage saturation limits
df -h

# Check raw drive mappings against existing volume setups
lsblk
```

---

## 🔗 Main Journey Resource
Track my continuous progress throughout the entire 90-day systems engineering pipeline here:
👉 [Production-Ready DevOps & SRE Journey](https://github.com/NB11-ML/Production-Ready-DevOps-SRE-Journey)
