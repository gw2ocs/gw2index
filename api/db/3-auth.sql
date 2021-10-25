\set jwt_secret `echo "$PGRST_JWT_SECRET"`
ALTER DATABASE gw2index SET "app.jwt_secret" TO :'jwt_secret';

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS auth;
GRANT usage ON SCHEMA auth TO web_anon, web_user;

DROP TYPE IF EXISTS auth.jwt_token cascade;
CREATE TYPE auth.jwt_token AS (
  token TEXT
);

CREATE TABLE IF NOT EXISTS auth.users (
  email			  TEXT PRIMARY KEY CHECK ( email ~* '^.+@.+\..+$' ),
  password	  TEXT NOT NULL CHECK (LENGTH(password) < 512),
  role			  NAME NOT NULL CHECK (LENGTH(role) < 512),
  profile_id  INTEGER NOT NULL REFERENCES api.profiles(id)
);


CREATE OR REPLACE FUNCTION auth.check_role_exists() RETURNS TRIGGER AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles AS r WHERE r.rolname = new.role) THEN
    raise foreign_key_violation USING message =
      'unknown database role: ' || new.role;
    RETURN NULL;
  END IF;
  RETURN new;
END
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS ensure_user_role_exists ON auth.users;
CREATE CONSTRAINT TRIGGER ensure_user_role_exists
  AFTER INSERT OR UPDATE ON auth.users
  FOR EACH ROW
  EXECUTE PROCEDURE auth.check_role_exists();


-- TODO: add blacklist table or column
CREATE OR REPLACE FUNCTION auth.check_token() RETURNS void
  LANGUAGE plpgsql
  AS $$
BEGIN
  IF current_setting('request.jwt.claim.email', true) =
     'disgruntled@mycompany.com' THEN
    raise insufficient_privilege
      USING hint = 'Nope, we are on to you';
  END IF;
END
$$;

CREATE OR REPLACE FUNCTION
auth.encrypt_password() RETURNS trigger AS $$
BEGIN
  IF tg_op = 'INSERT' OR new.password <> old.password THEN
    new.password = crypt(new.password, gen_salt('bf'));
  END IF;
  RETURN new;
END
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS encrypt_password ON auth.users;
CREATE TRIGGER encrypt_password
  BEFORE INSERT OR UPDATE ON auth.users
  FOR EACH ROW
  EXECUTE PROCEDURE auth.encrypt_password();
  

CREATE OR REPLACE FUNCTION
auth.login(email text, password text) RETURNS auth.jwt_token AS $$
DECLARE
  _user auth.users;
  result auth.jwt_token;
BEGIN
  -- check email and password
  SELECT users.* FROM auth.users
   WHERE users.email = login.email
     AND users.password = crypt(login.password, users.password)
  INTO _user;
  IF NOT FOUND THEN
    raise invalid_password USING message = 'invalid user or password';
  END IF;

  SELECT sign(
      row_to_json(r), current_setting('app.jwt_secret')
    ) AS token
    FROM (
      SELECT _user.role AS role, login.email AS email, _user.profile_id AS profile_id,
         extract(epoch FROM now())::INTEGER + 60*60 AS exp
    ) r
    INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION
auth.signup(username text, email text, password text) RETURNS void
AS $$
DECLARE
  profile api.profiles;
BEGIN
  INSERT INTO api.profiles (username) VALUES 
    (signup.username)
    RETURNING * into profile;
  INSERT INTO auth.users (email, password, role, profile_id) VALUES
    (signup.email, signup.password, 'web_user', profile.id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION auth.login(text,text) TO web_anon;
GRANT EXECUTE ON FUNCTION auth.signup(text,text,text) TO web_anon;