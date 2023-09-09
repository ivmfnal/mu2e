#!/bin/bash

source ./config.sh

$IN_DB_PSQL -q \
	> ./data/dims_float.csv \
	<< _EOF_

$create_active_files_view

-- float attrs
copy (
	select f.file_id, lower(pc.param_category) || '.' || lower(pt.param_type), param_value
        from active_files f
                inner join num_data_files_param_values dfv on f.file_id = dfv.file_id
                inner join param_types pt on pt.param_type_id = dfv.param_type_id
                inner join data_types dt on dt.data_type_id = pt.data_type_id
                inner join param_categories pc on pc.param_category_id = pt.param_category_id
        where dt.data_type = 'true_float'
                    and param_value is not null
        order by f.file_id
) to stdout;


_EOF_

preload_json_meta ./data/dims_float.csv
