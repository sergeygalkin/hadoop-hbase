#!/bin/bash - 
#===============================================================================
#
#          FILE: backup_list_hbase_tables_to_s3.sh
# 
#         USAGE: ./backup_list_hbase_tables_to_s3.sh
# 
#   DESCRIPTION: 
# 
#       OPTIONS: Configure MAX_TIME_DIFF (2 week now), HBASE_TABLES array and 
#                and S3_BUCKET inside script
#  REQUIREMENTS: Installed and configured s3cmd for backup user
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Sergey Galkin (),
#  ORGANIZATION: 
#       CREATED: 13.02.2017 08:37:19
#      REVISION:  ---
#===============================================================================

set -euo nounset                              # Treat unset variables as an error

export LANG=C
cd $(dirname $(realpath $0))

MAX_TIME_DIFF=$((60*60*24*14))
HBASE_TABLES=(table1 table2 table3)
S3_BUCKET="some-s3-bucket"


for DB in $HBASE_TABLES; do
  ALL_BACKUPS=$(s3cmd ls s3://${S3_BUCKET}/${DB}/ | grep DIR | wc -l )
  if [ ${ALL_BACKUPS} -gt 2 ]; then
      for NOT_NEED_BACKUP in $(s3cmd ls s3://${S3_BUCKET}/${DB}/ | grep DIR | awk -F '/' '{print $5}' | sort -n | head -n-2); do
         NOT_NEED_BACKUP_URL=$(s3cmd ls s3://${S3_BUCKET}/${DB}/ | grep DIR | grep $NOT_NEED_BACKUP | awk '{print $2}')
         echo "Found old backup - $NOT_NEED_BACKUP please remove it by s3cmd del -r ${NOT_NEED_BACKUP_URL}"
      done
  fi
  LAST_BACKUP_DATE=$(s3cmd ls s3://${S3_BUCKET}/${DB}/ | grep DIR  | awk -F '/' '{print $5}' | sort -n | tail -n1 |  awk -F '-auto-' '{print $2}' | awk -F '_' '{print $1}')
  if [ -n "$LAST_BACKUP_DATE" ]; then
    TIME_DIFF=$(($(date +%s)-$(date -d $LAST_BACKUP_DATE +%s)))
  else
    TIME_DIFF=$((${MAX_TIME_DIFF}+1))
  fi
  if [ $TIME_DIFF -ge $MAX_TIME_DIFF ]; then
          echo "${DB} is need to backup"
           /usr/local/bin/backup_hbase.sh ${DB}
  fi
done

