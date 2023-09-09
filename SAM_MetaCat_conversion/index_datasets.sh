#!/bin/bash

source ./config.sh

$OUT_DB_PSQL << _EOF_
\set on_error_stop on

alter table files_datasets add primary key (dataset_namespace, dataset_name, file_id);

create index dataset_did on datasets((namespace || ':' || name));
create index files_datasets_file_id on files_datasets(file_id);
create index datasets_meta_path_index on datasets using gin (metadata jsonb_path_ops);
create index datasets_meta_index on datasets using gin (metadata);

_EOF_

