#!/bin/bash

source ./config.sh

$IN_DB_PSQL -q > ./data/data_tiers.csv << _EOF_

$create_active_files_view

copy (
	select f.file_id, 'fn.tier', to_json(dt.data_tier)
		from active_files f, data_tiers dt 
		where f.data_tier_id = dt.data_tier_id
		order by f.file_id
) to stdout;



_EOF_

preload_json_meta ./data/data_tiers.csv
