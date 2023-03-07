# **DC Backup**

1. Login to MSP page https://<domain-name>:7080 and select DB Backup tab.

![](images/backup_msp_login.png)

2. Select “ADD FTP SERVER” button and add the ftp details, where the backup files should the uploaded.

![](images/backup_add_ftp_server.png)

3. Select “ADD BACKUP JOB” button and add the backup job with your required schedule.

![](images/backup_add_backup_job.png)

4. After adding the job, press “start” button to start DC backup. Backup files will be uploaded to the configured ftp location.

![](images/backup_start_backup_job.png)

# **DR restore**

1. Download deployment source and navigate to deployment/setup path and open restore.yml file. Specify the ftp details from where the backup files need to be fetched and the backup file names.

![](images/restore_config.png)

2. Confirm the target host machine details are proper in deployment/setup/master.yml file, before proceeding restore.

3. Start restore to target machine from deployment/setup folder. This will restore the director with the backup files. Run the following command.

   **`$ cd deployment/setup`**

   **`$ ./setup.sh <standalone> restore`**

4. Once restore complete, you can view all the data restored proper in the director page.
