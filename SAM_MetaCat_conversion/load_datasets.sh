#!/bin/bash

source ./config.sh

$OUT_DB_PSQL << _EOF_
\set on_error_stop on

drop table if exists 
    files_datasets, datasets, datasets_parent_child
    cascade
;

create table datasets
(
    namespace           text,
    name                text,
    primary key (namespace, name),

    frozen		boolean default 'false',
    monotonic		boolean default 'false',
    metadata    jsonb   default '{}',
    required_metadata   text[],
    creator             text,
    created_timestamp   timestamp with time zone     default now(),
    expiration          timestamp with time zone,
    description         text default '',
    file_metadata_requirements  jsonb   default '{}'::jsonb,
    file_count  bigint          default 0
);

insert into datasets(namespace, name, creator)
	(select distinct namespace, dataset, '$default_user' from temp_files_namespaces_datasets)
;

create table datasets_parent_child
(
    parent_namespace text,
    parent_name text,
    child_namespace text,
    child_name text,
    foreign key (parent_namespace, parent_name) references datasets(namespace, name) on delete cascade,
    foreign key (child_namespace, child_name) references datasets(namespace, name) on delete cascade,
    primary key (parent_namespace, parent_name, child_namespace, child_name)
);

create index datasets_pc_parent_specs on datasets_parent_child((parent_namespace || ':' || parent_name));
create index datasets_pc_child_specs on datasets_parent_child((child_namespace || ':' || child_name));
create index datasets_pc_child on datasets_parent_child(child_namespace, child_name);

create index dataset_did on datasets((namespace || ':' || name));
create index datasets_meta_path_index on datasets using gin (metadata jsonb_path_ops);
create index datasets_meta_index on datasets using gin (metadata);

--
-- populate datasets with files
--

create table files_datasets
(
    file_id                 text,
    dataset_namespace       text,
    dataset_name            text --,
    -- foreign key(dataset_namespace, dataset_name) references datasets(namespace, name) on delete cascade,
    -- primary key(dataset_namespace, dataset_name, file_id)
);       

insert into files_datasets(file_id, dataset_namespace, dataset_name)
	( select file_id, namespace, dataset from temp_files_namespaces_datasets );

-- create index files_datasets_file_id on files_datasets(file_id);


_EOF_

