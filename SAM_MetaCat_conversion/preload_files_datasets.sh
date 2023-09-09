#!/bin/bash

source ./config.sh

$IN_DB_PSQL -q \
	> ./data/files_datasets.csv \
	<< _EOF_

$create_active_files_view

copy (
    select f.file_id, pv.param_value
        from active_files f
                inner join data_files_param_values dfv on f.file_id = dfv.file_id
                inner join param_values pv on pv.param_value_id = dfv.param_value_id
                inner join param_types pt on pt.param_type_id = dfv.param_type_id
                inner join data_types dt on dt.data_type_id = pt.data_type_id
                inner join param_categories pc on pc.param_category_id = pt.param_category_id
        where dt.data_type = 'string' and pv.param_value is not null
		and pc.param_category = 'dh' and pt.param_type = 'dataset'
) to stdout;

_EOF_

$OUT_DB_PSQL << _EOF_

drop table if exists temp_files_datasets;

create table temp_files_datasets
(
        file_id text,
        dataset_name text
);

\copy temp_files_datasets(file_id, dataset_name) from 'data/files_datasets.csv';

_EOF_



