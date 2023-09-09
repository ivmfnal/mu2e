#!/bin/bash


source ./config.sh

$IN_DB_PSQL -q > ./data/lineages.csv << _EOF_

$create_active_files_view

copy (	select distinct l.file_id_source, l.file_id_dest
		from file_lineages l, active_files f1, active_files f2
		where f1.file_id = l.file_id_source and f2.file_id = l.file_id_dest
) to stdout

_EOF_


$OUT_DB_PSQL << _EOF_

drop view if exists file_provenance, files_with_provenance;

drop table if exists parent_child;

create table parent_child
(
	parent_id text,
	child_id text
);

create temp table temp_parent_child (
	like parent_child
);

\copy temp_parent_child(parent_id, child_id) from 'data/lineages.csv';

insert into parent_child(parent_id, child_id)
	(	select pc.parent_id, pc.child_id
			from temp_parent_child pc, files f1, files f2
			where f1.id = pc.parent_id and f2.id = pc.child_id
	);

alter table parent_child add primary key(parent_id, child_id);

create index parent_child_child on parent_child(child_id);

create view file_provenance as
    select f.id, 
        array(select parent_id from parent_child pc1 where pc1.child_id=f.id) as parents, 
        array(select child_id from parent_child pc2 where pc2.parent_id=f.id) as children
    from files f
;    

create view files_with_provenance as
    select f.*, r.children, r.parents
    from files f, file_provenance r
    where f.id = r.id
;

_EOF_
