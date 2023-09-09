#!/bin/bash

source ./config.sh

$IN_DB_PSQL -q \
	> ./data/dims_text.csv \
	<< _EOF_

$create_active_files_view

-- string attrs
copy (
   select f.file_id, 
		case
			when pc.param_category = 'dh' and pt.param_type = 'owner'		then 'fn.owner'
			when pc.param_category = 'dh' and pt.param_type = 'description'		then 'fn.description'
			when pc.param_category = 'dh' and pt.param_type = 'configuration'	then 'fn.configuration'
			when pc.param_category = 'dh' and pt.param_type = 'sequencer'		then 'fn.sequencer'
                        else lower(pc.param_category || '.' || pt.param_type)
		end,
                to_json(pv.param_value)
        from active_files f
                inner join data_files_param_values dfv on f.file_id = dfv.file_id
                inner join param_values pv on pv.param_value_id = dfv.param_value_id
                inner join param_types pt on pt.param_type_id = dfv.param_type_id
                inner join data_types dt on dt.data_type_id = pt.data_type_id
                inner join param_categories pc on pc.param_category_id = pt.param_category_id
        where dt.data_type = 'string' and pv.param_value is not null
		and not (
			pc.param_category = 'dh' and pt.param_type in ('sha256', 'source_file')
                        or lower(pc.param_category) = 'dataset' and lower(pt.param_type) = 'tag'
			or pc.param_category = 'job' and pt.param_type in ('site', 'node')
		)

) to stdout;



_EOF_

preload_json_meta ./data/dims_text.csv

