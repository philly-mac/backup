# Requirements
# openssl        -
# Rsync          - http://rsync.samba.org/
# s3cmd          - https://github.com/s3tools/s3cmd
# tar            - http://www.gnu.org/software/tar/
# rm             - http://pubs.opengroup.org/onlinepubs/9699919799/utilities/rm.html
# split
# Amazon s3      - http://aws.amazon.com/s3/

# Optional

# Postgres       - http://www.postgresql.org/

# Follow the individual instructions for each of the tools on how to set them up properly

# You will probably want to back up daily, so these are 2 lines that you can put
# into your crontab to do just that. Remove the comment hashes ofcourse ;)

# 0 1 * * 1           /opt/backup/backup full
# 0 2 * * 2,3,4,5,6,7 /opt/backup/backup inc

# TODO:
# Remove backups older than ... configurable
# Restore from method
# Delete local caches
# Rotate local logs
