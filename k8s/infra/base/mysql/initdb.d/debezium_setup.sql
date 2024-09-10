-- Create a Debezium user with a secure password
CREATE USER IF NOT EXISTS '{{DEBEZIUM_USERNAME}}'@'%' IDENTIFIED BY '{{DEBEZIUM_PASSWORD}}';

-- Grant necessary privileges for Debezium
GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO '{{DEBEZIUM_USERNAME}}'@'%';

-- Flush privileges to apply the changes
FLUSH PRIVILEGES;
