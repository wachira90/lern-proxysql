# Lerning ProxySQL

การใช้งาน **ProxySQL** แบบทีละขั้นตอนสามารถแบ่งออกเป็นหลายช่วง ตั้งแต่การติดตั้งไปจนถึงการตั้งค่าการใช้งานจริงกับฐานข้อมูล MySQL หรือ MariaDB ด้านล่างนี้คือคู่มือแบบ Step-by-Step:

---

## 🧩 ขั้นตอนที่ 1: ติดตั้ง ProxySQL

### บน Ubuntu/Debian:
```bash
sudo apt update
sudo apt install proxysql
```

### บน CentOS/RHEL:
```bash
sudo yum install https://github.com/sysown/proxysql/releases/download/v2.4.6/proxysql-2.4.6-1-centos7.x86_64.rpm
sudo yum install proxysql
```

---

## ⚙️ ขั้นตอนที่ 2: เริ่มต้น ProxySQL

```bash
sudo systemctl start proxysql
sudo systemctl enable proxysql
```

ProxySQL จะใช้พอร์ต `6032` สำหรับการจัดการ และ `6033` สำหรับการเชื่อมต่อฐานข้อมูล

---

## 🔐 ขั้นตอนที่ 3: เข้าสู่ระบบจัดการ ProxySQL

```bash
mysql -u admin -padmin -h 127.0.0.1 -P 6032
```

> ค่าเริ่มต้นคือ `admin/admin` (ควรเปลี่ยนรหัสผ่านทันที)

---

## 🗂️ ขั้นตอนที่ 4: เพิ่มเซิร์ฟเวอร์ฐานข้อมูล (MySQL/MariaDB)

```sql
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (0, '192.168.1.100', 3306);
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

- `hostgroup_id = 0` หมายถึงกลุ่ม primary/master
- สามารถเพิ่มหลายเซิร์ฟเวอร์เพื่อทำ load balancing ได้

---

## 👤 ขั้นตอนที่ 5: เพิ่มผู้ใช้งานฐานข้อมูล

```sql
INSERT INTO mysql_users (username, password, default_hostgroup) VALUES ('dbuser', 'dbpass', 0);
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
```

---

## 🔄 ขั้นตอนที่ 6: ตั้งค่า Query Rules (ถ้าต้องการ)

```sql
INSERT INTO mysql_query_rules (rule_id, match_pattern, destination_hostgroup, apply) VALUES (1, '^SELECT', 1, 1);
LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
```

> ตัวอย่างนี้จะส่งคำสั่ง SELECT ไปยัง hostgroup ที่เป็น replica (id = 1)

---

## 🧪 ขั้นตอนที่ 7: ทดสอบการเชื่อมต่อผ่าน ProxySQL

```bash
mysql -u dbuser -pdbpass -h 127.0.0.1 -P 6033
```

---

## 📊 ขั้นตอนที่ 8: ตรวจสอบสถานะ

```sql
SELECT * FROM runtime_mysql_servers;
SELECT * FROM stats_mysql_query_digest;
```

---

หากคุณต้องการตัวอย่างการตั้งค่าแบบ High Availability, การเชื่อมต่อกับ Cluster หรือการใช้ ProxySQL กับ Galera Cluster — ผมสามารถช่วยแนะนำเพิ่มเติมได้ครับ

คุณต้องการใช้ ProxySQL กับระบบแบบไหนครับ เช่น Master-Slave, Galera Cluster หรือแค่ Load Balancing ธรรมดา?

===

การตั้งค่า **ProxySQL** สำหรับ 3 รูปแบบหลัก ได้แก่ **Master-Slave**, **Galera Cluster**, และ **Load Balancing** สามารถทำได้ทีละขั้นตอนดังนี้:

---

## 🧭 1. Master-Slave Replication

### 📌 วัตถุประสงค์:
- อ่านจาก Slave
- เขียนไปยัง Master
- ลดภาระ Master ด้วยการกระจายการอ่าน

### ✅ ขั้นตอนการตั้งค่า:

#### 1.1 เพิ่มเซิร์ฟเวอร์ฐานข้อมูล
```sql
-- Master
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (10, 'master-db', 3306);

-- Slave
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (20, 'slave-db', 3306);

LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

#### 1.2 เพิ่มผู้ใช้งาน
```sql
INSERT INTO mysql_users (username, password, default_hostgroup) VALUES ('appuser', 'apppass', 10);
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
```

#### 1.3 ตั้งค่า Query Rules
```sql
-- ส่ง SELECT ไปยัง Slave
INSERT INTO mysql_query_rules (rule_id, match_pattern, destination_hostgroup, apply) 
VALUES (1, '^SELECT.*', 20, 1);

LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
```

---

## 🧭 2. Galera Cluster

### 📌 วัตถุประสงค์:
- ทุก Node สามารถอ่าน/เขียนได้
- ใช้ Load Balancing และ Failover

### ✅ ขั้นตอนการตั้งค่า:

#### 2.1 เพิ่มเซิร์ฟเวอร์ฐานข้อมูล
```sql
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (30, 'galera-node1', 3306);
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (30, 'galera-node2', 3306);
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (30, 'galera-node3', 3306);

LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

#### 2.2 เพิ่มผู้ใช้งาน
```sql
INSERT INTO mysql_users (username, password, default_hostgroup) VALUES ('appuser', 'apppass', 30);
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
```

#### 2.3 ตั้งค่า Load Balancing (ใช้ค่า default ก็ได้)
ProxySQL จะทำ Round-Robin โดยอัตโนมัติ

---

## 🧭 3. Load Balancing แบบทั่วไป (ไม่มี Replication)

### 📌 วัตถุประสงค์:
- กระจายโหลดไปยังหลายเซิร์ฟเวอร์ที่มีข้อมูลเหมือนกัน
- ใช้สำหรับระบบที่ sync ข้อมูลด้วยวิธีอื่น เช่น rsync หรือ DRBD

### ✅ ขั้นตอนการตั้งค่า:

#### 3.1 เพิ่มเซิร์ฟเวอร์ฐานข้อมูล
```sql
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (40, 'db1', 3306);
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (40, 'db2', 3306);

LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

#### 3.2 เพิ่มผู้ใช้งาน
```sql
INSERT INTO mysql_users (username, password, default_hostgroup) VALUES ('appuser', 'apppass', 40);
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
```

#### 3.3 ตั้งค่า Load Balancing
ProxySQL จะกระจายคำสั่งไปยังเซิร์ฟเวอร์ใน hostgroup 40 โดยอัตโนมัติ

---

## 📊 ตรวจสอบสถานะ

```sql
SELECT * FROM runtime_mysql_servers;
SELECT * FROM stats_mysql_query_digest;
```

---

หากคุณต้องการให้ผมช่วยสร้างไฟล์ config หรือสคริปต์สำหรับการตั้งค่าอัตโนมัติในแต่ละรูปแบบ ผมสามารถจัดทำให้ได้ครับ 😊 คุณสนใจรูปแบบไหนเป็นพิเศษ หรือใช้ร่วมกันหลายแบบ?

===

การตั้งค่า **ProxySQL** สำหรับ 3 รูปแบบหลัก ได้แก่ **Master-Slave**, **Galera Cluster**, และ **Load Balancing** สามารถทำได้ทีละขั้นตอนดังนี้:

---

## 🧭 1. Master-Slave Replication

### 📌 วัตถุประสงค์:
- อ่านจาก Slave
- เขียนไปยัง Master
- ลดภาระ Master ด้วยการกระจายการอ่าน

### ✅ ขั้นตอนการตั้งค่า:

#### 1.1 เพิ่มเซิร์ฟเวอร์ฐานข้อมูล
```sql
-- Master
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (10, 'master-db', 3306);

-- Slave
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (20, 'slave-db', 3306);

LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

#### 1.2 เพิ่มผู้ใช้งาน
```sql
INSERT INTO mysql_users (username, password, default_hostgroup) VALUES ('appuser', 'apppass', 10);
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
```

#### 1.3 ตั้งค่า Query Rules
```sql
-- ส่ง SELECT ไปยัง Slave
INSERT INTO mysql_query_rules (rule_id, match_pattern, destination_hostgroup, apply) 
VALUES (1, '^SELECT.*', 20, 1);

LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
```

---

## 🧭 2. Galera Cluster

### 📌 วัตถุประสงค์:
- ทุก Node สามารถอ่าน/เขียนได้
- ใช้ Load Balancing และ Failover

### ✅ ขั้นตอนการตั้งค่า:

#### 2.1 เพิ่มเซิร์ฟเวอร์ฐานข้อมูล
```sql
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (30, 'galera-node1', 3306);
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (30, 'galera-node2', 3306);
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (30, 'galera-node3', 3306);

LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

#### 2.2 เพิ่มผู้ใช้งาน
```sql
INSERT INTO mysql_users (username, password, default_hostgroup) VALUES ('appuser', 'apppass', 30);
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
```

#### 2.3 ตั้งค่า Load Balancing (ใช้ค่า default ก็ได้)
ProxySQL จะทำ Round-Robin โดยอัตโนมัติ

---

## 🧭 3. Load Balancing แบบทั่วไป (ไม่มี Replication)

### 📌 วัตถุประสงค์:
- กระจายโหลดไปยังหลายเซิร์ฟเวอร์ที่มีข้อมูลเหมือนกัน
- ใช้สำหรับระบบที่ sync ข้อมูลด้วยวิธีอื่น เช่น rsync หรือ DRBD

### ✅ ขั้นตอนการตั้งค่า:

#### 3.1 เพิ่มเซิร์ฟเวอร์ฐานข้อมูล
```sql
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (40, 'db1', 3306);
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (40, 'db2', 3306);

LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

#### 3.2 เพิ่มผู้ใช้งาน
```sql
INSERT INTO mysql_users (username, password, default_hostgroup) VALUES ('appuser', 'apppass', 40);
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
```

#### 3.3 ตั้งค่า Load Balancing
ProxySQL จะกระจายคำสั่งไปยังเซิร์ฟเวอร์ใน hostgroup 40 โดยอัตโนมัติ

---

## 📊 ตรวจสอบสถานะ

```sql
SELECT * FROM runtime_mysql_servers;
SELECT * FROM stats_mysql_query_digest;
```

---

หากคุณต้องการให้ผมช่วยสร้างไฟล์ config หรือสคริปต์สำหรับการตั้งค่าอัตโนมัติในแต่ละรูปแบบ ผมสามารถจัดทำให้ได้ครับ 😊 คุณสนใจรูปแบบไหนเป็นพิเศษ หรือใช้ร่วมกันหลายแบบ?


เรียบร้อยครับ! ผมได้สร้างไฟล์สคริปต์ `.sql` สำหรับการตั้งค่า **ProxySQL** ในทั้ง 3 รูปแบบ ได้แก่:

1. **Master-Slave Replication**
2. **Galera Cluster**
3. **General Load Balancing**

แต่ละส่วนมีคำสั่ง SQL สำหรับ:
- การเพิ่มเซิร์ฟเวอร์ฐานข้อมูล
- การเพิ่มผู้ใช้งาน
- การตั้งค่า query rules (ถ้ามี)
- การโหลดและบันทึกค่าไปยัง runtime และ disk

คุณสามารถดาวน์โหลดไฟล์ได้ที่นี่:

📄 [proxysql_config.sql](blob:https://m365.cloud.microsoft/7200ca12-0ad8-409a-9058-c7ef2253cd4d)

หากคุณต้องการให้ผมช่วยปรับแต่งค่าต่าง ๆ เช่น hostnames จริง, รหัสผ่านจริง, หรือเพิ่มการตรวจสอบสถานะเซิร์ฟเวอร์ — แจ้งผมได้เลยครับ!


```sql

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

```
