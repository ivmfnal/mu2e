#!/bin/bash

source ./config.sh

$IN_DB_PSQL -q > ./data/file_content_status.csv << _EOF_

$create_active_files_view

copy (
    select f.file_id, 'dh.status',to_json(fcs.file_content_status)
        		from active_files f, file_content_statuses fcs
        		where f.file_content_status_id = fcs.file_content_status_id
) to stdout;



_EOF_

preload_json_meta ./data/file_content_status.csv
