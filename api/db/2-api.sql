CREATE SCHEMA IF NOT EXISTS api;
GRANT usage ON SCHEMA api TO web_anon, web_user;

CREATE TABLE api.profiles (
  id SERIAL PRIMARY KEY,
  username TEXT NOT NULL
);

GRANT SELECT ON api.profiles TO web_anon, web_user;

CREATE TABLE api.paths (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  parent_id INTEGER REFERENCES api.paths(id)
);

GRANT SELECT ON api.paths TO web_anon, web_user;


CREATE TABLE api.items (
  id INTEGER PRIMARY KEY,
  path_id INTEGER REFERENCES api.paths(id),
  mime TEXT
);

GRANT SELECT ON api.items TO web_anon;
GRANT SELECT, INSERT ON api.items TO web_user;

CREATE TABLE api.item_descriptions (
  id SERIAL PRIMARY KEY,
  item_id INTEGER REFERENCES api.items(id),
  content TEXT
);

GRANT SELECT ON api.item_descriptions TO web_anon;
GRANT ALL ON api.item_descriptions TO web_user;
GRANT USAGE, SELECT ON SEQUENCE api.item_descriptions_id_seq TO web_user;