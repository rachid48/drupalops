# Module: efs

This module provisions an encrypted Amazon EFS file system and mount targets for Drupal file storage.

## Why this module

Shared storage is required so multiple web instances can access the same Drupal files and uploaded assets. EFS provides a managed, scalable NFS file system that keeps content consistent across the ASG.

## Resources created

- `aws_efs_file_system.drupal` — creates the encrypted EFS file system.
- `aws_security_group.efs` — restricts NFS access to the Drupal web server security group.
- `aws_efs_mount_target.az1` — mount target in the first subnet/AZ.
- `aws_efs_mount_target.az2` — mount target in the second subnet/AZ.

## Inputs

Name | Type | Description
--- | --- | ---
vpc_id | string | VPC ID where EFS will be created
subnet_ids | list(string) | List of subnet IDs for EFS mount targets (one per AZ)
web_sg_id | string | Security group ID of web EC2 instances allowed to mount EFS

## Outputs

Name | Description
--- | ---
efs_id | EFS file system ID
efs_dns_name | EFS DNS name used to mount the file system

## Example usage

```hcl
module "efs" {
  source     = "./modules/efs"
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.main.id, aws_subnet.main_2.id]
  web_sg_id  = aws_security_group.web.id
}
```

## Dependencies

This module is consumed by `module.compute` for the shared Drupal filesystem mount. It does not depend on other modules under `modules/`.
