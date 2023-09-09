#!/bin/bash

source ./config.sh

echo dumping data ...

$IN_DB_PSQL -q \
	> ./data/app_families.csv \
	<< _EOF_

$create_active_files_view

copy
(
	select f.file_id, 'app.version', to_json(a.version)
	    from active_files f, application_families a where a.appl_family_id = f.appl_family_id
) to stdout;

copy
(
	select f.file_id, 'app.family', to_json(a.family)
	    from active_files f, application_families a where a.appl_family_id = f.appl_family_id
) to stdout;

copy
(
	select f.file_id, 'app.name', to_json(a.appl_name)
	    from active_files f, application_families a where a.appl_family_id = f.appl_family_id
) to stdout;

_EOF_


preload_json_meta ./data/app_families.csv

