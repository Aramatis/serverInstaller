CREATE DATABASE ghostinspector;
CREATE USER inspector WITH PASSWORD '1ghost2inspector';
GRANT ALL PRIVILEGES ON DATABASE ghostinspector TO inspector;
ALTER USER inspector CREATEDB;
\q
