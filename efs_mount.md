Accessing a standalone Amazon Elastic File System (EFS) involves several steps including setting up the EFS, configuring
network access, and mounting the EFS on a client (like an EC2 instance). Here's a general guide on how to do this:

### Step 1: Create the EFS File System

```text
This step is performed in the provided terraform
```

1. **Via AWS Management Console**:
    - Go to the EFS section in the AWS Management Console.
    - Click "Create file system".
    - Follow the wizard to configure the file system settings, such as VPC, availability zones, and mount targets.

2. **Via AWS CLI or Terraform**:
    - You can also create and configure EFS using the AWS CLI or Terraform, as per your operational practices.

### Step 2: Configure Network Access

```text
This step is performed in the provided terraform
```

1. **Set up Mount Targets**: Ensure that mount targets are created for your EFS in each of the VPC's subnets where you
   want to access the EFS.

2. **Configure Security Groups**: The security groups associated with the mount targets should allow inbound NFS
   traffic (typically on port 2049) from the resources that need to access the EFS.

### Step 3: Install NFS Client on Your EC2 Instance

To mount an EFS file system on an EC2 instance, the instance must have an NFS client installed.

- For Amazon Linux or RHEL-based systems:
  ```bash
  sudo yum install -y nfs-utils
  ```

- For Ubuntu or Debian-based systems:
  ```bash
  sudo apt-get install -y nfs-common
  ```

### Step 4: Mount the EFS on the EC2 Instance

1. **Create a Mount Point**:
   ```bash
   sudo mkdir -p /efs/mnt
   ```

2. **Mount the EFS File System**:
    - You can find the DNS name of your EFS file system in the AWS Management Console (under the EFS section).
    - Mount the EFS using:
      ```bash
      sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 {EFS-DNS-Name}:/ /efs/mnt
      ```

3. **Automatic Mount on Reboot** (Optional):
    - Edit `/etc/fstab` to add an entry for the EFS to automatically mount it on system reboots.
    - Add the following line:
      ```
      {EFS-DNS-Name}:/ /efs/mnt nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 0 0
      ```

### Step 5: Verify the Mount

- Check that the EFS is mounted successfully:
  ```bash
  df -hT
  ```

### Step 6: Create a directory for vmagent configs

  ```bash
  mkdir -p /efs/mnt/vmagent-cfgs
  ```

### Step 7: Mount the [vmagent](vmagent.yaml) config

  ```bash
  scp ./vmagent.yaml username@ec2_host_ip:/efs/mnt/vmagent-cfgs
  ```

### Additional Considerations

- **IAM Permissions**: Ensure your IAM policies allow for EFS creation and management.
- **Encryption**: Consider whether to enable encryption at rest and in transit for your EFS file system.
- **Backup**: Set up AWS Backup if you need regular backups of your EFS file system.

Remember, EFS file systems can be accessed by multiple EC2 instances simultaneously, making them suitable for shared
file storage use cases.
