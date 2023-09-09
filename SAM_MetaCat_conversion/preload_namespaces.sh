#!/bin/bash

source ./config.sh

$IN_DB_PSQL -q \
	> ./data/namespaces.csv \
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

copy (
	select distinct value
		from text_dimensions, persons
		where category='dh' and name='owner'
			and persons.username = value
) to stdout;


_EOF_

