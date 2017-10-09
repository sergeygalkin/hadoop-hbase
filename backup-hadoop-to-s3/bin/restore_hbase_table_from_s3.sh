#!/bin/bash -
#===============================================================================
#
#          FILE: restore_hbase_table_from_s3.sh
#
#         USAGE: ./restore_hbase_table_from_s3.sh S3_BUCKET HTABLE HBASE_SNAPSHOT HBASE_URL
#
#   DESCRIPTION:
#
#       OPTIONS: HBASE_URL example is 'hdfs://server.example.com:9000/hbase/'
#  REQUIREMENTS: Installed and configured s3cmd for backup user
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Sergey Galkin (),
#  ORGANIZATION:
#       CREATED: 14.02.2017 09:20:19
#      REVISION:  ---
#===============================================================================

set -euo nounset                              # Treat unset variables as an error
if [ ! -f ${HOME}/.s3cfg ]; then echo "Please install and configure s3cmd"; exit 1; fi

S3_ID=$(grep access_key ${HOME}/.s3cfg | awk '{print $3}')
S3_PASS=$(grep secret_key ${HOME}/.s3cfg | awk '{print $3}')
S3_BUCKET=$1
HTABLE=$2
HSNAPSHOT=$3
HBASE_URL=$4

if [ -z "${S3_ID}" ]; then echo "Please install and configure s3cmd"; exit 1; fi
if [ -z "${S3_PASS}" ]; then echo "Please install and configure s3cmd"; exit 1; fi
if [ -z "${HTABLE}" -o -z "${S3_BUCKET}" -o -z "${HSNAPSHOT}" -o -z "${HBASE_URL}" ]; then
   echo "Usage: $(basename $0) s3_bucket htable table_snapshot_name hbase_url"
   exit 1
fi
S3_URL="s3n://${S3_ID}:${S3_PASS}@${S3_BUCKET}/${HTABLE}/${HSNAPSHOT}/"

hbase org.apache.hadoop.hbase.snapshot.ExportSnapshot \
 -snapshot "${HBASE_SNAPSHOT}" \
 -bandwidth 4 -mappers 4 \
 -copy-from ${S3_URL} \
 -copy-to ${HBASE_URL} \
 -overwrite