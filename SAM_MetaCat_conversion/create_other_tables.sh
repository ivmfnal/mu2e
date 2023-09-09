#!/bin/bash

source ./config.sh

$OUT_DB_PSQL << _EOF_

drop table if exists queries cascade;

create table queries
(
    namespace       text references namespaces(name),
    name            text,
    primary key(namespace, name),
    parameters      text[],
    source          text,
    creator         text references users(username),
    created_timestamp   timestamp with time zone     default now(),
    description     text,
    metadata        jsonb default '{}'
);

_EOF_



