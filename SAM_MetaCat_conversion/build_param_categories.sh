#!/bin/bash

source ./config.sh


$OUT_DB_PSQL -q <<_EOF_

drop table if exists parameter_categories;

create table parameter_categories
(
    path        text    primary key,
    
    owner_user          text        references  users(username),
    owner_role          text        references  roles(name),
    
    check ( (owner_user is null ) != (owner_role is null) ),
    
    restricted  boolean default 'false',
    description         text default '',
    creator             text references users(username),
    created_timestamp   timestamp with time zone     default now(),
    definitions         jsonb	default '{}'::jsonb 
);

insert into parameter_categories(path, owner_user, creator)
	( select distinct split_part(name, '.', 1), '$default_user', '$default_user'
		from meta
        );

insert into parameter_categories(path, owner_user, creator)
	values('.', '$default_user', '$default_user')
;
    
_EOF_

