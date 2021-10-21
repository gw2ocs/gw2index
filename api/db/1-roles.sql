\set auth_pass `echo "$PGRST_DB_AUTH_PASSWORD"`

CREATE ROLE web_anon NOLOGIN;

CREATE ROLE web_user NOLOGIN;

CREATE ROLE authenticator NOINHERIT LOGIN PASSWORD :'auth_pass';
GRANT web_anon TO authenticator;
GRANT web_user TO authenticator;
