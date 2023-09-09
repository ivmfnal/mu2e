#!/bin/bash

source ./config.sh

$IN_DB_PSQL -q \
	> ./data/attrs_2.csv \
	<< _EOF_

$create_active_files_view

copy ( 
    select df.file_id, 'rse.nevent', df.event_count
                from active_files df
                where df.event_count is not null
) to stdout;


_EOF_

preload_json_meta ./data/attrs_2.csv




