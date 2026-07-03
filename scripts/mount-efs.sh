#!/bin/bash
# ============================================
# Reusable EFS mount script for AWS instances
# Compatible with Amazon Linux 2023
# Usage: source this script or call it with efs_id and mount_path as env vars
# ============================================

EFS_ID="${efs_id}"
MOUNT_PATH="${mount_path}"
REGION="${aws_region}"

# Wait for EFS mount target to be available across AZs
echo "Waiting for EFS mount target to be available..."
sleep 20

# Create mount point if not exists
mkdir -p "$MOUNT_PATH"

# Mount EFS via NFS4 (more reliable than efs-utils on AL2023)
echo "Mounting EFS $EFS_ID to $MOUNT_PATH..."
mount -t nfs4 \
  -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 \
  "$EFS_ID.efs.$REGION.amazonaws.com:/" \
  "$MOUNT_PATH"

# Persist mount across reboots
echo "$EFS_ID.efs.$REGION.amazonaws.com:/ $MOUNT_PATH nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev 0 0" >> /etc/fstab

echo "EFS mounted successfully at $MOUNT_PATH"
