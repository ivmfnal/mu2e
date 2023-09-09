#!/bin/bash

source ./config.sh

$IN_DB_PSQL -q  > data/files.csv << _EOF_
\set on_error_stop on

$create_active_files_view
 
--
-- checksums
--

create temp view file_checksums as
    select df.file_id, jsonb_object(array_agg(array[ckt.checksum_name, ck.checksum_value])) as checksums
    from data_files df 
        inner join checksums ck on ck.file_id=df.file_id 
        inner join checksum_types ckt on ckt.checksum_type_id=ck.checksum_type_id 
    group by df.file_id
;

-- use temp_files_namespaces_datasets

copy (	
    select df.file_id, df.file_name, 
                extract(epoch from df.create_date), pc.username, 
                extract(epoch from df.update_date), pu.username, 
                df.file_size_in_bytes,
                coalesce(fck.checksums, '{}'::jsonb)
        from active_files df
                left outer join persons pc on pc.person_id = df.create_user_id
                left outer join persons pu on pu.person_id = df.update_user_id
                left outer join file_checksums fck on fck.file_id = df.file_id
) to stdout;

_EOF_

$OUT_DB_PSQL << _EOF_

drop table if exists raw_files cascade;

\echo importing raw files

create table raw_files
(
        file_id	    text,
        namespace   text,
        name		text,
        create_timestamp	double precision,
        create_user	text,
        update_timestamp	double precision,
        update_user	text,
        size		bigint,
        checksums   jsonb
);

create temp table raw_data(		-- raw files excluding the namespace - get namespace from temp_files_namespaces_datasets
        file_id     bigint,
        name            text,
        create_timestamp        double precision,
        create_user     text,
        update_timestamp        double precision,
        update_user     text,
        size            bigint,
        checksums   jsonb
);

\copy raw_data(file_id, name, create_timestamp, create_user, update_timestamp, update_user, size, checksums) from 'data/files.csv';

insert into raw_files(file_id, namespace, name, create_timestamp, create_user, update_timestamp, update_user, size, checksums)
	( select r.file_id::text, fnd.namespace, r.name, r.create_timestamp, r.create_user, 
			r.update_timestamp, r.update_user, r.size, r.checksums
		from raw_data r, temp_files_namespaces_datasets fnd
			where fnd.file_id = r.file_id
        )
;

create index raw_file_id on raw_files(file_id);

_EOF_
