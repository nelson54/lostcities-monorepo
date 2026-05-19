CREATE USER accounts WITH ENCRYPTED PASSWORD 'example';
CREATE DATABASE "lostcities-accounts" WITH ENCODING = 'UTF8' CONNECTION LIMIT = -1;
GRANT ALL PRIVILEGES ON DATABASE "lostcities-accounts" TO accounts;
GRANT ALL PRIVILEGES ON DATABASE "lostcities-accounts" TO postgres;

CREATE USER matches WITH ENCRYPTED PASSWORD 'example';
CREATE DATABASE "lostcities-matches" WITH ENCODING = 'UTF8' CONNECTION LIMIT = -1;
GRANT ALL PRIVILEGES ON DATABASE "lostcities-matches" TO matches;
GRANT ALL PRIVILEGES ON DATABASE "lostcities-matches" TO posgres;

CREATE USER gamestate WITH ENCRYPTED PASSWORD 'example';
CREATE DATABASE "lostcities-gamestate" WITH ENCODING = 'UTF8' CONNECTION LIMIT = -1;
GRANT ALL PRIVILEGES ON DATABASE "lostcities-gamestate" TO gamestate;
GRANT ALL PRIVILEGES ON DATABASE "lostcities-gamestate" TO postgres;
