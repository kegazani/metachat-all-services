SELECT 'CREATE DATABASE metachat' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'metachat')\gexec
SELECT 'CREATE DATABASE metachat_personality' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'metachat_personality')\gexec
SELECT 'CREATE DATABASE metachat_analytics' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'metachat_analytics')\gexec
SELECT 'CREATE DATABASE metachat_mood' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'metachat_mood')\gexec
SELECT 'CREATE DATABASE metachat_biometric' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'metachat_biometric')\gexec
SELECT 'CREATE DATABASE metachat_correlation' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'metachat_correlation')\gexec

GRANT ALL PRIVILEGES ON DATABASE metachat TO metachat;
GRANT ALL PRIVILEGES ON DATABASE metachat_personality TO metachat;
GRANT ALL PRIVILEGES ON DATABASE metachat_analytics TO metachat;
GRANT ALL PRIVILEGES ON DATABASE metachat_mood TO metachat;
GRANT ALL PRIVILEGES ON DATABASE metachat_biometric TO metachat;
GRANT ALL PRIVILEGES ON DATABASE metachat_correlation TO metachat;

\c metachat;
GRANT ALL ON SCHEMA public TO metachat;

\c metachat_personality;
GRANT ALL ON SCHEMA public TO metachat;

\c metachat_analytics;
GRANT ALL ON SCHEMA public TO metachat;

\c metachat_mood;
GRANT ALL ON SCHEMA public TO metachat;

\c metachat_biometric;
GRANT ALL ON SCHEMA public TO metachat;

\c metachat_correlation;
GRANT ALL ON SCHEMA public TO metachat;
