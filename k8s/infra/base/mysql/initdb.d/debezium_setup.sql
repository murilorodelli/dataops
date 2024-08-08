-- Create a Debezium user with a secure password
CREATE USER IF NOT EXISTS 'debezium'@'%' IDENTIFIED BY '{{DEBEZIUM_USER_PASSWORD}}';

-- Grant necessary privileges for Debezium
GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'debezium'@'%';

-- Flush privileges to apply the changes
FLUSH PRIVILEGES;
