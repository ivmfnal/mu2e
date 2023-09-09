#!/bin/bash

source ./config.sh

$IN_DB_PSQL -q \
	> ./data/files_datasets_namespaces.csv \
	<< _EOF_

$create_active_files_view

create temp view text_dimensions as

   select f.file_id, pt.param_type as name, pc.param_category as category,
                pv.param_value as value
        from active_files f
                inner join data_files_param_values dfv on f.file_id = dfv.file_id
                inner join param_values pv on pv.param_value_id = dfv.param_value_id
                inner join param_types pt on pt.param_type_id = dfv.param_type_id
                inner join data_types dt on dt.data_type_id = pt.data_type_id
                inner join param_categories pc on pc.param_category_id = pt.param_category_id
        where dt.data_type = 'string' and pv.param_value is not null
;

copy (	-- file_id, namespace, dataset
	select distinct df.file_id, dim1.value as namespace, dim2.value as dataset
		from data_files df, text_dimensions dim1, text_dimensions dim2, persons p
			where df.file_id = dim1.file_id and dim1.category='dh' and dim1.name='owner'
				and df.file_id = dim2.file_id and dim2.category='dh' and dim2.name='dataset'
			        and p.username = dim1.value
) to stdout;


_EOF_

$OUT_DB_PSQL << _EOF_

drop table if exists temp_files_namespaces_datasets;

create table temp_files_namespaces_datasets( file_id bigint, namespace text, dataset text );

\copy temp_files_namespaces_datasets from './data/files_datasets_namespaces.csv';

create index fnd_file_id on temp_files_namespaces_datasets(file_id);
create index fnd_dataset on temp_files_namespaces_datasets(dataset);

_EOF_

