#!/bin/bash

source config.sh

echo URL: $url

$OUT_DB_PSQL << _EOF_
create temp table temp_auth( username text, auth_info jsonb, auid text );

\copy temp_auth(username, auth_info, auid) from 'data/auth_info.csv'

update users u
    set auth_info=coalesce(u.auth_info, '{}'::jsonb) || coalesce(t.auth_info, '{}'::jsonb),
        auid=coalesce(u.auid, t.auid)
    from temp_auth t
    where t.username = u.username
;

_EOF_

echo --- non-LDAP authenticators saved

