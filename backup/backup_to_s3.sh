#!/bin/bash - 
#===============================================================================
#
#          FILE: backup_to_s3.sh
# 
#         USAGE: ./backup_to_s3.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Sergey Galkin (),
#  ORGANIZATION: 
#       CREATED: 12.02.2017 11:19:36
#      REVISION:  ---
#===============================================================================

set -eo nounset                              # Treat unset variables as an error


if [ ! -f ${HOME}/.s3cfg ]; then echo "Please install and configure s3cmd"; exit 1; fi

S3_ID=$(grep access_key ${HOME}/.s3cfg | awk '{print $3}')
S3_PASS=$(grep secret_key ${HOME}/.s3cfg | awk '{print $3}')
S3_BUCKET=$1
DATE=$(date +%F_%H-%M)
HTABLE=$2
HSTATUS=true
if [ -z "${S3_ID}" ]; then echo "Please install and configure s3cmd"; exit 1; fi
if [ -z "${S3_PASS}" ]; then echo "Please install and configure s3cmd"; exit 1; fi
if [ -z "${HTABLE}" -o -z "${S3_BUCKET}" ]; then echo "Usage: $(basename $0) s3_bucket table_name"; exit 1; fi
HSNAPSHOT="${HTABLE}-auto-$DATE"
LOG_FILE=$(mktemp -u)
echo "$(date '+%F %H:%M') Staring backup, log file available in ${LOG_FILE}"
echo "$(date '+%F %H:%M') Create snapshot ${HSNAPSHOT}" | tee -a ${LOG_FILE}
echo "snapshot '${HTABLE}', '${HSNAPSHOT}'" | hbase shell &>> ${LOG_FILE}
echo "$(date '+%F %H:%M') Start export snapshot to S3" | tee -a ${LOG_FILE}
S3_URL="s3n://${S3_ID}:${S3_PASS}@${S3_BUCKET}/${HTABLE}/${HSNAPSHOT}/"
hbase org.apache.hadoop.hbase.snapshot.ExportSnapshot -Dfs.s3n.multipart.uploads.enabled=true -Dfs.s3n.multipart.copy.block.size=2684354560 -Dmapreduce.task.timeout=6000000 -snapshot "${HSNAPSHOT}" -bandwidth 4 -mappers 4 -copy-to ${S3_URL} &>> ${LOG_FILE} ||  HSTATUS=false
echo "$(date '+%F %H:%M') Snapshot exporting finished" | tee -a ${LOG_FILE}
echo "$(date '+%F %H:%M') Delete snapshot ${HSNAPSHOT}" | tee -a  ${LOG_FILE}
echo "delete_snapshot '${HSNAPSHOT}'" | hbase shell  &>> ${LOG_FILE}
if [ "$HSTATUS" = false ]; then
    echo "Something wrong !"
    echo "=============================== LOG =============================== "
    cat ${LOG_FILE}
    echo "============================= END LOG =============================="
    echo "Delete incorrect backup s3://${S3_BUCKET}/${HTABLE}/${HSNAPSHOT}"
    s3cmd del -r s3://${S3_BUCKET}/${HTABLE}/${HSNAPSHOT} > /dev/null
else
    echo "$(date '+%F %H:%M') Calculate size of s3://${S3_BUCKET}/"
    s3cmd du -H s3://${S3_BUCKET}/
    s3cmd du -H s3://${S3_BUCKET}/${HTABLE}
    s3cmd du -H s3://${S3_BUCKET}/${HTABLE}/${HSNAPSHOT}
fi
rm ${LOG_FILE}
