#!/bin/bash

source ./config.sh

$OUT_DB_PSQL << _EOF_

drop table if exists namespaces cascade;

create table namespaces
(
    name                text    primary key,
    check( name != ''),

    description         text,

    owner_user          text references users(username),
    owner_role          text references roles(name),
    check ( (owner_user is null ) != (owner_role is null) ),

    creator             text,
    created_timestamp   timestamp with time zone        default now(),
    file_count  bigint  default 0
);

insert into namespaces(name, description, owner_user, owner_role, creator)
	( select distinct namespace, '', 
			case -- owner user
				when namespace = 'mu2e' then null
				else namespace
			end,
			case -- owner role
				when namespace != 'mu2e' then null
				else 'pro'
			end, 
                        '$default_user'
		from temp_files_namespaces_datasets
        )
;
		

_EOF_


