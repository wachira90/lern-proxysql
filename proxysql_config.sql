
-- =========================================
-- ProxySQL Configuration: Master-Slave Setup
-- =========================================

-- Add MySQL Servers
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (10, 'master-db', 3306);
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (20, 'slave-db', 3306);
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;

-- Add MySQL Users
INSERT INTO mysql_users (username, password, default_hostgroup) VALUES ('appuser', 'apppass', 10);
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;

-- Add Query Rules
INSERT INTO mysql_query_rules (rule_id, match_pattern, destination_hostgroup, apply) 
VALUES (1, '^SELECT.*', 20, 1);
LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;

-- =========================================
-- ProxySQL Configuration: Galera Cluster Setup
-- =========================================

-- Add Galera Nodes
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (30, 'galera-node1', 3306);
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (30, 'galera-node2', 3306);
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (30, 'galera-node3', 3306);
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;

-- Add MySQL Users
INSERT INTO mysql_users (username, password, default_hostgroup) VALUES ('appuser', 'apppass', 30);
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;

-- =========================================
-- ProxySQL Configuration: General Load Balancing
-- =========================================

-- Add Load Balanced Servers
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (40, 'db1', 3306);
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (40, 'db2', 3306);
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;

-- Add MySQL Users
INSERT INTO mysql_users (username, password, default_hostgroup) VALUES ('appuser', 'apppass', 40);
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
