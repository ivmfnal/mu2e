#!/bin/bash

source ./config.sh

$IN_DB_PSQL -q > ./data/file_formats.csv << _EOF_

$create_active_files_view

copy (

	select f.file_id, 'fn.format', to_json(ff.file_format)
		from active_files f, file_formats ff
		where f.file_format_id = ff.file_format_id
) to stdout;



_EOF_

preload_json_meta ./data/file_formats.csv
