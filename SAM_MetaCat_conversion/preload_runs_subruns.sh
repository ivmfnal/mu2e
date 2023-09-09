#!/bin/bash

source ./config.sh

$IN_DB_PSQL -q > ./data/runs_subruns.csv << _EOF_

$create_active_files_view

create temp view temp_runs_subruns as
	select distinct df.file_id as file_id, r.run_number as run, dfr.subrun_number as subrun
		from active_files df
			inner join data_files_runs dfr on dfr.file_id = df.file_id
			inner join runs r on r.run_id = dfr.run_id
		where r.run_number is not null and dfr.subrun_number is not null
;

create temp view temp_runs as
	select distinct df.file_id as file_id, r.run_number as run
		from active_files df
			inner join data_files_runs dfr on dfr.file_id = df.file_id
			inner join runs r on r.run_id = dfr.run_id
		where r.run_number is not null
;

copy
( 
    select file_id, 'rs.runs', to_json(array_agg(run::bigint*1000000+subrun::bigint)::bigint[])
        from temp_runs_subruns where subrun is not null 
        group by file_id 
) to stdout;

_EOF_

preload_json_meta ./data/runs_subruns.csv int_a


