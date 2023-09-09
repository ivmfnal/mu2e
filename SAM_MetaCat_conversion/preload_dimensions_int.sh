#!/bin/bash

source ./config.sh

$IN_DB_PSQL -q \
	> ./data/dims_int.csv \
	<< _EOF_

$create_active_files_view

-- int attrs
copy (
	select f.file_id, 
                case
                        when pc.param_category = 'dh' and pt.param_type = 'first_run_subrun'    then 'rs.first_run'
                        when pc.param_category = 'dh' and pt.param_type = 'last_run_subrun'     then 'rs.last_run'
                        when pc.param_category = 'dh' and pt.param_type = 'first_subrun'        then 'rs.first_subrun'
                        when pc.param_category = 'dh' and pt.param_type = 'last_subrun'         then 'rs.last_subrun'
                        when pc.param_category = 'dh' and pt.param_type = 'first_run_event'     then 'rse.first_run'
                        when pc.param_category = 'dh' and pt.param_type = 'last_run_event'      then 'rse.last_run'
                        when pc.param_category = 'dh' and pt.param_type = 'first_subrun_event'  then 'rse.first_subrun'
                        when pc.param_category = 'dh' and pt.param_type = 'last_subrun_event'   then 'rse.last_subrun'
                        when pc.param_category = 'dh' and pt.param_type = 'first_event'         then 'rse.first_event'
                        when pc.param_category = 'dh' and pt.param_type = 'last_event'          then 'rse.last_event'
                        when pc.param_category = 'dh' and pt.param_type = 'gencount'            then 'gen.count'
                        else lower(pc.param_category || '.' || pt.param_type)
                end,
		param_value
        from active_files f
                inner join num_data_files_param_values dfv on f.file_id = dfv.file_id
                inner join param_types pt on pt.param_type_id = dfv.param_type_id
                inner join data_types dt on dt.data_type_id = pt.data_type_id
                inner join param_categories pc on pc.param_category_id = pt.param_category_id
        where dt.data_type='true_int'
                    and param_value is not null
        order by f.file_id
) to stdout;


_EOF_

preload_json_meta ./data/dims_int.csv

