\set auth_pass `echo "$PGRST_DB_AUTH_PASSWORD"`

create role web_anon nologin;
grant usage on schema api to web_anon;

create role authenticator noinherit login password :'auth_pass';
grant web_anon to authenticator;
