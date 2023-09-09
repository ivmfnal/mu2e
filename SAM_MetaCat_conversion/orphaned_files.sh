#!/bin/bash

source ./config.sh

$IN_DB_PSQL -q \
	> ./data/orphans.csv \
	<< _EOF_

$create_active_files_view_all

create temp view text_dimensions as

   select f.file_id, pc.param_category || '.' || pt.param_type as name, pc.param_category as category,
                pv.param_value as value
        from active_files f
                inner join data_files_param_values dfv on f.file_id = dfv.file_id
                inner join param_values pv on pv.param_value_id = dfv.param_value_id
                inner join param_types pt on pt.param_type_id = dfv.param_type_id
                inner join data_types dt on dt.data_type_id = pt.data_type_id
                inner join param_categories pc on pc.param_category_id = pt.param_category_id
        where dt.data_type = 'string' and pv.param_value is not null
;

create temp view files_datasets as
	select distinct t1.file_id, t1.value as owner, t2.value as name
		from text_dimensions t1, text_dimensions t2
		where t1.file_id = t2.file_id
			and t1.category='dh' and t2.category='dh'
			and t1.name='dh.owner' and t2.name='dh.dataset'
                order by t2.value
;

copy (
	select file_id from active_files where not exists (
		select * from files_datasets where files_datasets.file_id = active_files.file_id
	)
) to stdout;



_EOF_

