/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19-12.3.2-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: infra_watch
-- ------------------------------------------------------
-- Server version	12.3.2-MariaDB-ubu2404

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*M!100616 SET @OLD_NOTE_VERBOSITY=@@NOTE_VERBOSITY, NOTE_VERBOSITY=0 */;

--
-- Table structure for table `alert_rules`
--

DROP TABLE IF EXISTS `alert_rules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `alert_rules` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `server_service_id` int(11) NOT NULL,
  `metric_name` varchar(50) NOT NULL,
  `threshold_min` decimal(8,2) DEFAULT NULL,
  `threshold_max` decimal(8,2) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `server_service_id` (`server_service_id`),
  CONSTRAINT `1` FOREIGN KEY (`server_service_id`) REFERENCES `server_services` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `alert_rules`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `alert_rules` WRITE;
/*!40000 ALTER TABLE `alert_rules` DISABLE KEYS */;
INSERT INTO `alert_rules` VALUES
(1,1,'cpu_usage',0.00,85.00,1),
(2,2,'cpu_usage',0.00,90.00,1),
(3,3,'disk_io',0.00,500.00,1),
(4,4,'ram_usage',0.00,80.00,0),
(5,5,'response_time',0.00,200.00,1),
(6,6,'error_rate',0.00,5.00,1),
(7,7,'cpu_usage',0.00,75.00,1),
(8,8,'ram_usage',0.00,85.00,1),
(9,9,'connections',0.00,1000.00,1),
(10,10,'packet_loss',0.00,2.00,1),
(11,11,'cache_hit_ratio',50.00,100.00,1),
(12,12,'memory_usage',0.00,90.00,0),
(13,13,'queue_depth',0.00,5000.00,1),
(14,14,'lag_ms',0.00,1000.00,1),
(15,15,'ingest_rate',0.00,10000.00,1),
(16,16,'index_latency',0.00,500.00,0),
(17,17,'dns_queries',0.00,50000.00,1),
(18,18,'resolution_time',0.00,100.00,1),
(19,19,'storage_used',0.00,80.00,1),
(20,20,'bandwidth',0.00,1000.00,1),
(21,21,'pod_restarts',0.00,3.00,1),
(22,22,'etcd_latency',0.00,50.00,1),
(23,23,'consul_checks',0.00,10.00,1),
(24,24,'auth_failures',0.00,5.00,1),
(25,25,'ticket_latency',0.00,200.00,1),
(26,26,'agent_uptime',90.00,100.00,1),
(27,27,'log_volume',0.00,5000.00,0),
(28,28,'shipper_errors',0.00,10.00,1),
(29,29,'build_duration',0.00,600.00,1),
(30,30,'repo_size',0.00,50000.00,0),
(31,31,'vault_seals',0.00,1.00,1),
(32,32,'radius_timeouts',0.00,5.00,1),
(33,33,'ldap_binds',0.00,1000.00,1),
(34,34,'kerberos_tickets',0.00,500.00,1),
(35,35,'ci_queue',0.00,50.00,1),
(36,36,'artifact_count',0.00,10000.00,1),
(37,37,'sonar_issues',0.00,100.00,1),
(38,38,'jira_tickets',0.00,500.00,1),
(39,39,'haproxy_sessions',0.00,2000.00,1),
(40,40,'vrrp_state',0.00,1.00,1),
(41,41,'es_heap',0.00,75.00,1),
(42,42,'logstash_queue',0.00,1000.00,1),
(43,43,'kafka_lag',0.00,5000.00,1),
(44,44,'rabbit_conns',0.00,500.00,1),
(45,45,'gluster_bricks',0.00,10.00,1),
(46,46,'nfs_latency',0.00,50.00,0),
(47,47,'snmp_errors',0.00,20.00,1),
(48,48,'syslog_drops',0.00,100.00,1),
(49,49,'ntp_offset',0.00,50.00,1),
(50,50,'smtp_queue',0.00,200.00,1);
/*!40000 ALTER TABLE `alert_rules` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `incidents`
--

DROP TABLE IF EXISTS `incidents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `incidents` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `alert_rule_id` int(11) NOT NULL,
  `triggered_at` timestamp NULL DEFAULT current_timestamp(),
  `resolved_at` timestamp NULL DEFAULT NULL,
  `severity` enum('low','medium','high','critical') DEFAULT 'medium',
  `status` enum('open','acknowledged','resolved') DEFAULT 'open',
  `description` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `alert_rule_id` (`alert_rule_id`),
  KEY `idx_incidents_status_triggered` (`status`,`triggered_at`),
  KEY `idx_incidents_triggered_alert_severity` (`triggered_at`,`alert_rule_id`,`severity`),
  CONSTRAINT `1` FOREIGN KEY (`alert_rule_id`) REFERENCES `alert_rules` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `incidents`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `incidents` WRITE;
/*!40000 ALTER TABLE `incidents` DISABLE KEYS */;
INSERT INTO `incidents` VALUES
(1,1,'2026-03-10 14:22:10','2026-03-10 15:00:00','high','resolved','CPU spike on web frontend'),
(2,3,'2026-03-15 09:15:00','2026-03-15 10:30:00','medium','resolved','Disk IO saturation on DB node'),
(3,5,'2026-03-20 16:40:22','2026-03-20 17:10:00','low','resolved','Elevated response time on app server'),
(4,7,'2026-03-25 08:05:11','2026-03-25 08:45:00','high','acknowledged','Monitoring node CPU threshold breach'),
(5,9,'2026-04-02 11:20:33','2026-04-02 12:00:00','medium','resolved','Load balancer connection pool exhaustion'),
(6,11,'2026-04-08 13:55:44','2026-04-08 14:30:00','low','resolved','Cache hit ratio dropped below 60 percent'),
(7,13,'2026-04-14 19:10:05','2026-04-14 20:00:00','critical','resolved','Message broker queue depth critical'),
(8,15,'2026-04-20 07:30:22','2026-04-20 08:15:00','medium','acknowledged','Log ingestion rate anomaly detected'),
(9,17,'2026-04-25 10:45:11','2026-04-25 11:30:00','low','resolved','DNS query volume spike'),
(10,19,'2026-05-01 15:20:33','2026-05-01 16:00:00','high','resolved','Backup storage usage exceeded 80 percent'),
(11,21,'2026-05-05 09:00:44','2026-05-05 09:45:00','medium','resolved','Kubernetes pod restart loop detected'),
(12,23,'2026-05-08 14:15:05','2026-05-08 15:00:00','low','resolved','Consul health check failures'),
(13,25,'2026-05-11 18:30:22','2026-05-11 19:15:00','high','acknowledged','Authentication service latency increase'),
(14,27,'2026-05-14 06:45:11','2026-05-14 07:30:00','medium','resolved','Log forwarder buffer overflow'),
(15,29,'2026-05-16 11:00:33','2026-05-16 11:45:00','low','resolved','CI pipeline duration exceeded threshold'),
(16,31,'2026-05-18 16:20:44','2026-05-18 17:00:00','critical','resolved','Vault auto-seal triggered unexpectedly'),
(17,33,'2026-05-20 08:35:05','2026-05-20 09:15:00','medium','resolved','LDAP bind rate anomaly'),
(18,35,'2026-05-22 13:50:22','2026-05-22 14:30:00','high','acknowledged','CI runner queue backlog growing'),
(19,37,'2026-05-24 17:05:11','2026-05-24 17:50:00','low','resolved','SonarQube critical issues count increased'),
(20,39,'2026-05-26 09:20:33','2026-05-26 10:00:00','medium','resolved','HAProxy session table near capacity'),
(21,41,'2026-05-28 14:35:44','2026-05-28 15:15:00','high','resolved','Elasticsearch heap usage warning'),
(22,43,'2026-05-29 07:50:05','2026-05-29 08:30:00','critical','acknowledged','Kafka consumer lag critical'),
(23,45,'2026-05-30 12:05:22','2026-05-30 12:45:00','medium','resolved','GlusterFS brick offline event'),
(24,47,'2026-05-31 16:20:11','2026-05-31 17:00:00','low','resolved','SNMP polling errors detected'),
(25,49,'2026-06-01 08:35:33','2026-06-01 09:15:00','high','resolved','NTP offset exceeded safe threshold'),
(26,2,'2026-06-01 13:50:44','2026-06-01 14:30:00','medium','resolved','Secondary web node CPU warning'),
(27,4,'2026-06-02 18:05:05','2026-06-02 18:45:00','low','open','Memory usage trending upward'),
(28,6,'2026-06-02 09:20:22','2026-06-02 10:00:00','high','acknowledged','Application error rate spike'),
(29,8,'2026-06-03 14:35:11','2026-06-03 15:15:00','medium','resolved','Grafana node memory pressure'),
(30,10,'2026-06-03 19:50:33','2026-06-03 20:30:00','low','resolved','Keepalived packet loss detected'),
(31,12,'2026-06-04 08:05:44','2026-06-04 08:45:00','high','open','Cache node memory critical'),
(32,14,'2026-06-04 13:20:05','2026-06-04 14:00:00','medium','resolved','Kafka replication lag warning'),
(33,16,'2026-06-04 17:35:22','2026-06-04 18:15:00','low','resolved','Kibana index latency elevated'),
(34,18,'2026-06-05 09:50:11','2026-06-05 10:30:00','high','acknowledged','Unbound resolution timeout'),
(35,20,'2026-06-05 14:05:33','2026-06-05 14:45:00','medium','resolved','MinIO bandwidth saturation'),
(36,22,'2026-03-12 18:20:44','2026-03-12 19:00:00','low','resolved','Etcd write latency warning'),
(37,24,'2026-03-18 08:35:05','2026-03-18 09:15:00','high','resolved','IAM auth failure rate increase'),
(38,26,'2026-03-22 13:50:22','2026-03-22 14:30:00','medium','open','Telegraf agent uptime drop'),
(39,28,'2026-03-28 17:05:11','2026-03-28 17:45:00','low','resolved','Filebeat shipping errors'),
(40,30,'2026-04-03 09:20:33','2026-04-03 10:00:00','high','acknowledged','GitLab repository size warning'),
(41,32,'2026-04-09 14:35:44','2026-04-09 15:15:00','medium','resolved','RADIUS timeout threshold breach'),
(42,34,'2026-04-15 18:50:05','2026-04-15 19:30:00','low','resolved','Kerberos ticket renewal delay'),
(43,36,'2026-04-21 08:05:22','2026-04-21 08:45:00','high','resolved','Nexus artifact count warning'),
(44,38,'2026-04-27 13:20:11','2026-04-27 14:00:00','medium','open','Jira ticket backlog growth'),
(45,40,'2026-05-03 17:35:33','2026-05-03 18:15:00','low','resolved','VRRP state flapping detected'),
(46,42,'2026-05-09 09:50:44','2026-05-09 10:30:00','high','acknowledged','Logstash queue backlog'),
(47,44,'2026-05-15 14:05:05','2026-05-15 14:45:00','medium','resolved','RabbitMQ connection limit warning'),
(48,46,'2026-05-21 18:20:22','2026-05-21 19:00:00','low','resolved','NFS latency spike'),
(49,48,'2026-05-27 08:35:11','2026-05-27 09:15:00','high','resolved','Syslog message drops detected'),
(50,50,'2026-06-02 13:50:33','2026-06-02 14:30:00','medium','open','SMTP queue depth warning');
/*!40000 ALTER TABLE `incidents` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `maintenance_windows`
--

DROP TABLE IF EXISTS `maintenance_windows`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `maintenance_windows` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `server_id` int(11) NOT NULL,
  `start_time` datetime NOT NULL,
  `end_time` datetime NOT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `created_by_user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `server_id` (`server_id`),
  KEY `created_by_user_id` (`created_by_user_id`),
  CONSTRAINT `1` FOREIGN KEY (`server_id`) REFERENCES `servers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `2` FOREIGN KEY (`created_by_user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `CONSTRAINT_1` CHECK (`end_time` > `start_time`)
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `maintenance_windows`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `maintenance_windows` WRITE;
/*!40000 ALTER TABLE `maintenance_windows` DISABLE KEYS */;
INSERT INTO `maintenance_windows` VALUES
(1,1,'2026-04-01 02:00:00','2026-04-01 04:00:00','Nginx version upgrade',1),
(2,2,'2026-04-05 02:00:00','2026-04-05 03:30:00','Apache config optimization',2),
(3,3,'2026-04-10 03:00:00','2026-04-10 05:00:00','MySQL minor patch',3),
(4,4,'2026-04-15 01:00:00','2026-04-15 04:00:00','PostgreSQL vacuum and reindex',4),
(5,5,'2026-04-20 02:30:00','2026-04-20 03:30:00','Redis memory tuning',5),
(6,6,'2026-04-25 03:00:00','2026-04-25 04:30:00','Memcached restart',6),
(7,7,'2026-05-01 02:00:00','2026-05-01 03:00:00','Prometheus retention update',7),
(8,8,'2026-05-05 02:00:00','2026-05-05 03:30:00','Grafana plugin update',8),
(9,9,'2026-05-10 01:30:00','2026-05-10 03:00:00','HAProxy certificate renewal',9),
(10,10,'2026-05-15 02:00:00','2026-05-15 03:00:00','Keepalived config sync',10),
(11,11,'2026-05-20 03:00:00','2026-05-20 04:00:00','Cache node OS patch',11),
(12,12,'2026-05-25 02:00:00','2026-05-25 05:00:00','Hardware diagnostics',12),
(13,13,'2026-05-30 01:00:00','2026-05-30 03:00:00','RabbitMQ cluster rebalance',13),
(14,14,'2026-06-01 02:30:00','2026-06-01 04:00:00','Kafka broker upgrade',14),
(15,15,'2026-06-02 03:00:00','2026-06-02 04:30:00','Logstash pipeline refactor',15),
(16,16,'2026-06-02 02:00:00','2026-06-02 05:00:00','Kibana index migration',16),
(17,17,'2026-06-03 01:00:00','2026-06-03 02:30:00','Bind9 zone update',17),
(18,18,'2026-06-03 02:00:00','2026-06-03 03:00:00','Unbound cache flush',18),
(19,19,'2026-06-04 03:00:00','2026-06-04 04:00:00','Backup script optimization',19),
(20,20,'2026-06-04 02:00:00','2026-06-04 03:30:00','Storage array firmware',20),
(21,21,'2026-06-04 01:30:00','2026-06-04 03:00:00','K8s control plane patch',21),
(22,22,'2026-06-05 02:00:00','2026-06-05 04:00:00','Etcd defragmentation',22),
(23,23,'2026-06-05 03:00:00','2026-06-05 04:30:00','Consul snapshot restore test',23),
(24,24,'2026-06-05 02:00:00','2026-06-05 03:00:00','Windows security update',24),
(25,25,'2026-06-05 01:00:00','2026-06-05 02:30:00','AD sync maintenance',25),
(26,26,'2026-06-10 02:30:00','2026-06-10 04:00:00','Edge router firmware',26),
(27,27,'2026-06-15 03:00:00','2026-06-15 05:00:00','Remote link diagnostics',27),
(28,28,'2026-06-20 02:00:00','2026-06-20 03:30:00','IoT gateway update',28),
(29,29,'2026-06-25 01:00:00','2026-06-25 02:00:00','QA environment reset',29),
(30,30,'2026-06-30 02:00:00','2026-06-30 04:00:00','Test data refresh',30),
(31,31,'2026-07-01 03:00:00','2026-07-01 04:30:00','Firewall rule audit',31),
(32,32,'2026-07-02 02:00:00','2026-07-02 03:00:00','IDS signature update',32),
(33,33,'2026-07-03 01:30:00','2026-07-03 03:00:00','IAM policy rotation',33),
(34,34,'2026-07-04 02:00:00','2026-07-04 03:30:00','Kerberos keytab renewal',34),
(35,35,'2026-07-05 03:00:00','2026-07-05 04:00:00','CI runner scaling test',35),
(36,36,'2026-07-06 02:00:00','2026-07-06 03:00:00','Artifact cleanup job',36),
(37,37,'2026-07-07 01:00:00','2026-07-07 02:30:00','SonarQube DB migration',37),
(38,38,'2026-07-08 02:30:00','2026-07-08 04:00:00','Jira index rebuild',38),
(39,39,'2026-07-09 03:00:00','2026-07-09 04:30:00','LB algorithm change',39),
(40,40,'2026-07-10 02:00:00','2026-07-10 03:00:00','VRRP priority adjustment',40),
(41,41,'2026-07-11 01:00:00','2026-07-11 03:00:00','Elastic cluster rolling restart',41),
(42,42,'2026-07-12 02:00:00','2026-07-12 03:30:00','Logstash filter update',42),
(43,43,'2026-07-13 03:00:00','2026-07-13 04:00:00','Kafka topic retention change',43),
(44,44,'2026-07-14 02:00:00','2026-07-14 03:00:00','RabbitMQ policy update',44),
(45,45,'2026-07-15 01:30:00','2026-07-15 03:00:00','Gluster volume expand',45),
(46,46,'2026-07-16 02:00:00','2026-07-16 04:00:00','NFS export refresh',46),
(47,47,'2026-07-17 03:00:00','2026-07-17 04:30:00','SNMP community rotation',47),
(48,48,'2026-07-18 02:00:00','2026-07-18 03:00:00','Syslog server migration',48),
(49,49,'2026-07-19 01:00:00','2026-07-19 02:30:00','NTP source update',49),
(50,50,'2026-07-20 02:00:00','2026-07-20 03:30:00','SMTP relay config change',50);
/*!40000 ALTER TABLE `maintenance_windows` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `server_services`
--

DROP TABLE IF EXISTS `server_services`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `server_services` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `server_id` int(11) NOT NULL,
  `service_id` int(11) NOT NULL,
  `status` enum('up','down','degraded') DEFAULT 'up',
  `last_checked` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_server_service` (`server_id`,`service_id`),
  KEY `service_id` (`service_id`),
  CONSTRAINT `1` FOREIGN KEY (`server_id`) REFERENCES `servers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `2` FOREIGN KEY (`service_id`) REFERENCES `services` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `server_services`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `server_services` WRITE;
/*!40000 ALTER TABLE `server_services` DISABLE KEYS */;
INSERT INTO `server_services` VALUES
(1,1,1,'up','2026-03-10 12:00:00'),
(2,2,2,'up','2026-03-10 12:05:00'),
(3,3,3,'up','2026-03-10 12:10:00'),
(4,4,4,'down','2026-03-10 12:15:00'),
(5,5,5,'up','2026-03-10 12:20:00'),
(6,6,6,'degraded','2026-03-10 12:25:00'),
(7,7,12,'up','2026-03-10 12:30:00'),
(8,8,13,'up','2026-03-10 12:35:00'),
(9,9,14,'up','2026-03-10 12:40:00'),
(10,10,15,'up','2026-03-10 12:45:00'),
(11,11,5,'up','2026-03-10 12:50:00'),
(12,12,6,'down','2026-03-10 12:55:00'),
(13,13,7,'up','2026-03-10 13:00:00'),
(14,14,8,'up','2026-03-10 13:05:00'),
(15,15,10,'up','2026-03-10 13:10:00'),
(16,16,11,'down','2026-03-10 13:15:00'),
(17,17,16,'up','2026-03-10 13:20:00'),
(18,18,17,'up','2026-03-10 13:25:00'),
(19,19,38,'up','2026-03-10 13:30:00'),
(20,20,39,'up','2026-03-10 13:35:00'),
(21,21,20,'up','2026-03-10 13:40:00'),
(22,22,21,'up','2026-03-10 13:45:00'),
(23,23,22,'degraded','2026-03-10 13:50:00'),
(24,24,44,'up','2026-03-10 13:55:00'),
(25,25,45,'up','2026-03-10 14:00:00'),
(26,26,33,'up','2026-03-10 14:05:00'),
(27,27,34,'down','2026-03-10 14:10:00'),
(28,28,35,'up','2026-03-10 14:15:00'),
(29,29,24,'up','2026-03-10 14:20:00'),
(30,30,25,'down','2026-03-10 14:25:00'),
(31,31,23,'up','2026-03-10 14:30:00'),
(32,32,46,'up','2026-03-10 14:35:00'),
(33,33,44,'up','2026-03-10 14:40:00'),
(34,34,45,'up','2026-03-10 14:45:00'),
(35,35,24,'up','2026-03-10 14:50:00'),
(36,36,26,'up','2026-03-10 14:55:00'),
(37,37,27,'up','2026-03-10 15:00:00'),
(38,38,28,'up','2026-03-10 15:05:00'),
(39,39,14,'up','2026-03-10 15:10:00'),
(40,40,15,'degraded','2026-03-10 15:15:00'),
(41,41,9,'up','2026-03-10 15:20:00'),
(42,42,10,'up','2026-03-10 15:25:00'),
(43,43,8,'up','2026-03-10 15:30:00'),
(44,44,7,'up','2026-03-10 15:35:00'),
(45,45,41,'up','2026-03-10 15:40:00'),
(46,46,42,'down','2026-03-10 15:45:00'),
(47,47,47,'up','2026-03-10 15:50:00'),
(48,48,48,'up','2026-03-10 15:55:00'),
(49,49,31,'up','2026-03-10 16:00:00'),
(50,50,32,'up','2026-03-10 16:05:00');
/*!40000 ALTER TABLE `server_services` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `servers`
--

DROP TABLE IF EXISTS `servers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `servers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `hostname` varchar(100) NOT NULL,
  `ip_address` varchar(45) NOT NULL,
  `os_type` varchar(50) DEFAULT NULL,
  `location` varchar(100) DEFAULT NULL,
  `status` enum('online','offline','maintenance') DEFAULT 'online',
  `team_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `team_id` (`team_id`),
  KEY `idx_servers_os_type` (`os_type`),
  CONSTRAINT `1` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `servers`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `servers` WRITE;
/*!40000 ALTER TABLE `servers` DISABLE KEYS */;
INSERT INTO `servers` VALUES
(1,'srv-web-01','10.0.1.10','Ubuntu 22.04','Moscow DC1','online',1),
(2,'srv-web-02','10.0.1.11','Ubuntu 22.04','Moscow DC1','online',1),
(3,'srv-db-01','10.0.2.10','Debian 11','Moscow DC2','online',5),
(4,'srv-db-02','10.0.2.11','Debian 11','Moscow DC2','maintenance',5),
(5,'srv-app-01','10.0.3.10','CentOS 8','SPb DC1','online',7),
(6,'srv-app-02','10.0.3.11','CentOS 8','SPb DC1','offline',7),
(7,'srv-mon-01','10.0.4.10','AlmaLinux 9','Kazan DC1','online',6),
(8,'srv-mon-02','10.0.4.11','AlmaLinux 9','Kazan DC1','online',6),
(9,'srv-lb-01','10.0.5.10','Ubuntu 22.04','Moscow DC1','online',36),
(10,'srv-lb-02','10.0.5.11','Ubuntu 22.04','Moscow DC1','online',36),
(11,'srv-cache-01','10.0.6.10','Debian 11','SPb DC2','online',33),
(12,'srv-cache-02','10.0.6.11','Debian 11','SPb DC2','offline',33),
(13,'srv-mq-01','10.0.7.10','CentOS 8','Moscow DC3','online',34),
(14,'srv-mq-02','10.0.7.11','CentOS 8','Moscow DC3','online',34),
(15,'srv-log-01','10.0.8.10','AlmaLinux 9','Kazan DC2','online',26),
(16,'srv-log-02','10.0.8.11','AlmaLinux 9','Kazan DC2','maintenance',26),
(17,'srv-dns-01','10.0.9.10','Ubuntu 22.04','Moscow DC1','online',35),
(18,'srv-dns-02','10.0.9.11','Ubuntu 22.04','Moscow DC1','online',35),
(19,'srv-bkp-01','10.0.10.10','Debian 11','SPb DC1','online',38),
(20,'srv-bkp-02','10.0.10.11','Debian 11','SPb DC1','online',38),
(21,'srv-k8s-01','10.0.11.10','Ubuntu 22.04','Moscow DC2','online',7),
(22,'srv-k8s-02','10.0.11.11','Ubuntu 22.04','Moscow DC2','online',7),
(23,'srv-k8s-03','10.0.11.12','Ubuntu 22.04','Moscow DC2','offline',7),
(24,'srv-win-01','10.0.12.10','Windows Server 2022','SPb DC3','online',19),
(25,'srv-win-02','10.0.12.11','Windows Server 2022','SPb DC3','online',19),
(26,'srv-edge-01','10.0.13.10','AlmaLinux 9','Remote Site A','online',9),
(27,'srv-edge-02','10.0.13.11','AlmaLinux 9','Remote Site B','offline',9),
(28,'srv-edge-03','10.0.13.12','AlmaLinux 9','Remote Site C','online',9),
(29,'srv-test-01','10.0.14.10','CentOS 8','QA Lab','online',49),
(30,'srv-test-02','10.0.14.11','CentOS 8','QA Lab','maintenance',49),
(31,'srv-sec-01','10.0.15.10','Ubuntu 22.04','Moscow DC1','online',4),
(32,'srv-sec-02','10.0.15.11','Ubuntu 22.04','Moscow DC1','online',4),
(33,'srv-iam-01','10.0.16.10','Debian 11','SPb DC1','online',25),
(34,'srv-iam-02','10.0.16.11','Debian 11','SPb DC1','online',25),
(35,'srv-ci-01','10.0.17.10','Ubuntu 22.04','Dev Lab','online',10),
(36,'srv-ci-02','10.0.17.11','Ubuntu 22.04','Dev Lab','online',10),
(37,'srv-art-01','10.0.18.10','AlmaLinux 9','SPb DC2','online',10),
(38,'srv-art-02','10.0.18.11','AlmaLinux 9','SPb DC2','online',10),
(39,'srv-gw-01','10.0.19.10','CentOS 8','Moscow DC1','online',30),
(40,'srv-gw-02','10.0.19.11','CentOS 8','Moscow DC1','offline',30),
(41,'srv-search-01','10.0.20.10','Debian 11','Kazan DC1','online',32),
(42,'srv-search-02','10.0.20.11','Debian 11','Kazan DC1','online',32),
(43,'srv-stream-01','10.0.21.10','Ubuntu 22.04','Moscow DC3','online',31),
(44,'srv-stream-02','10.0.21.11','Ubuntu 22.04','Moscow DC3','online',31),
(45,'srv-virt-01','10.0.22.10','AlmaLinux 9','SPb DC1','online',29),
(46,'srv-virt-02','10.0.22.11','AlmaLinux 9','SPb DC1','maintenance',29),
(47,'srv-patch-01','10.0.23.10','CentOS 8','Moscow DC2','online',27),
(48,'srv-patch-02','10.0.23.11','CentOS 8','Moscow DC2','online',27),
(49,'srv-audit-01','10.0.24.10','Ubuntu 22.04','Kazan DC2','online',39),
(50,'srv-audit-02','10.0.24.11','Ubuntu 22.04','Kazan DC2','online',39);
/*!40000 ALTER TABLE `servers` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `services`
--

DROP TABLE IF EXISTS `services`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `services` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `port` int(11) NOT NULL,
  `protocol` varchar(20) DEFAULT 'TCP',
  `description` text DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `services`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `services` WRITE;
/*!40000 ALTER TABLE `services` DISABLE KEYS */;
INSERT INTO `services` VALUES
(1,'Nginx',80,'TCP','Web server frontend'),
(2,'Apache',8080,'TCP','Legacy web server'),
(3,'MySQL',3306,'TCP','Relational database'),
(4,'PostgreSQL',5432,'TCP','Advanced RDBMS'),
(5,'Redis',6379,'TCP','In-memory cache'),
(6,'Memcached',11211,'TCP','Distributed cache'),
(7,'RabbitMQ',5672,'TCP','Message broker'),
(8,'Kafka',9092,'TCP','Event streaming platform'),
(9,'Elasticsearch',9200,'TCP','Search and analytics'),
(10,'Logstash',5044,'TCP','Log ingestion pipeline'),
(11,'Kibana',5601,'TCP','Visualization dashboard'),
(12,'Prometheus',9090,'TCP','Metrics collection'),
(13,'Grafana',3000,'TCP','Monitoring dashboards'),
(14,'HAProxy',8443,'TCP','Load balancer'),
(15,'Keepalived',112,'UDP','VRRP failover'),
(16,'Bind9',53,'UDP','DNS resolver'),
(17,'Unbound',5353,'UDP','Recursive DNS'),
(18,'OpenSSH',22,'TCP','Secure shell access'),
(19,'Docker API',2376,'TCP','Container management'),
(20,'Kube API',6443,'TCP','Kubernetes control plane'),
(21,'Etcd',2379,'TCP','Cluster state store'),
(22,'Consul',8500,'TCP','Service discovery'),
(23,'Vault',8200,'TCP','Secrets management'),
(24,'Jenkins',8081,'TCP','CI/CD automation'),
(25,'GitLab',8444,'TCP','Source code hosting'),
(26,'Nexus',8082,'TCP','Artifact repository'),
(27,'SonarQube',9000,'TCP','Code quality analysis'),
(28,'Jira',8083,'TCP','Issue tracking'),
(29,'Confluence',8090,'TCP','Documentation wiki'),
(30,'Mattermost',8065,'TCP','Team messaging'),
(31,'Zabbix',10051,'TCP','Infrastructure monitoring'),
(32,'Icinga',5665,'TCP','Service monitoring'),
(33,'Telegraf',8125,'UDP','Metrics agent'),
(34,'Fluentd',24224,'TCP','Log forwarder'),
(35,'Filebeat',5045,'TCP','Lightweight shipper'),
(36,'Metricbeat',5066,'TCP','System metrics shipper'),
(37,'Alertmanager',9093,'TCP','Alert routing'),
(38,'Thanos',10902,'TCP','Long-term metrics storage'),
(39,'MinIO',9001,'TCP','S3-compatible storage'),
(40,'Ceph',6789,'TCP','Distributed storage cluster'),
(41,'GlusterFS',24007,'TCP','Scale-out NAS'),
(42,'NFS',2049,'TCP','Network file system'),
(43,'SMB',445,'TCP','Windows file sharing'),
(44,'LDAP',389,'TCP','Directory service'),
(45,'Kerberos',88,'UDP','Network authentication'),
(46,'RADIUS',1812,'UDP','AAA protocol'),
(47,'SNMP',161,'UDP','Network management'),
(48,'Syslog',514,'UDP','System logging'),
(49,'NTP',123,'UDP','Time synchronization'),
(50,'SMTP',25,'TCP','Mail transfer agent');
/*!40000 ALTER TABLE `services` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `sla_policies`
--

DROP TABLE IF EXISTS `sla_policies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sla_policies` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `team_id` int(11) NOT NULL,
  `target_uptime_pct` decimal(5,2) NOT NULL CHECK (`target_uptime_pct` between 0 and 100),
  `measurement_period_days` int(11) NOT NULL DEFAULT 30,
  PRIMARY KEY (`id`),
  KEY `team_id` (`team_id`),
  CONSTRAINT `1` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sla_policies`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `sla_policies` WRITE;
/*!40000 ALTER TABLE `sla_policies` DISABLE KEYS */;
INSERT INTO `sla_policies` VALUES
(1,1,99.90,30),
(2,2,99.50,30),
(3,3,99.95,60),
(4,4,99.80,30),
(5,5,99.99,90),
(6,6,99.70,30),
(7,7,99.85,60),
(8,8,99.60,30),
(9,9,99.40,30),
(10,10,99.75,60),
(11,11,99.30,30),
(12,12,99.50,30),
(13,13,99.80,90),
(14,14,99.90,60),
(15,15,99.65,30),
(16,16,99.85,30),
(17,17,99.70,60),
(18,18,99.55,30),
(19,19,99.40,30),
(20,20,99.60,60),
(21,21,99.75,30),
(22,22,99.50,30),
(23,23,99.90,90),
(24,24,99.65,30),
(25,25,99.80,60),
(26,26,99.70,30),
(27,27,99.55,30),
(28,28,99.45,60),
(29,29,99.60,30),
(30,30,99.75,30),
(31,31,99.85,60),
(32,32,99.50,30),
(33,33,99.70,30),
(34,34,99.65,60),
(35,35,99.80,30),
(36,36,99.90,90),
(37,37,99.55,30),
(38,38,99.75,60),
(39,39,99.60,30),
(40,40,99.85,30),
(41,41,99.95,60),
(42,42,99.70,30),
(43,43,99.65,30),
(44,44,99.50,60),
(45,45,99.80,30),
(46,46,99.75,30),
(47,47,99.60,60),
(48,48,99.55,30),
(49,49,99.40,30),
(50,50,99.90,90);
/*!40000 ALTER TABLE `sla_policies` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `system_settings`
--

DROP TABLE IF EXISTS `system_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `system_settings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `setting_key` varchar(100) NOT NULL,
  `setting_value` text DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `updated_by_user_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `setting_key` (`setting_key`),
  KEY `updated_by_user_id` (`updated_by_user_id`),
  CONSTRAINT `1` FOREIGN KEY (`updated_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `system_settings`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `system_settings` WRITE;
/*!40000 ALTER TABLE `system_settings` DISABLE KEYS */;
INSERT INTO `system_settings` VALUES
(1,'alert_email_enabled','true','2026-02-01 10:00:00',1),
(2,'alert_slack_webhook','https://hooks.slack.com/mock','2026-02-02 10:00:00',2),
(3,'metrics_retention_days','30','2026-02-03 10:00:00',3),
(4,'log_retention_days','60','2026-02-04 10:00:00',4),
(5,'default_timezone','Europe/Moscow','2026-02-05 10:00:00',5),
(6,'max_login_attempts','5','2026-02-06 10:00:00',6),
(7,'session_timeout_min','30','2026-02-07 10:00:00',7),
(8,'password_min_length','12','2026-02-08 10:00:00',8),
(9,'enable_2fa','true','2026-02-09 10:00:00',9),
(10,'api_rate_limit','1000','2026-02-10 10:00:00',10),
(11,'dashboard_refresh_sec','15','2026-02-11 10:00:00',11),
(12,'export_format_default','csv','2026-02-12 10:00:00',12),
(13,'maintenance_notification','true','2026-02-13 10:00:00',13),
(14,'sla_calculation_method','rolling','2026-02-14 10:00:00',14),
(15,'incident_auto_close_hours','72','2026-02-15 10:00:00',15),
(16,'alert_cooldown_min','10','2026-02-16 10:00:00',16),
(17,'max_concurrent_exports','3','2026-02-17 10:00:00',17),
(18,'ui_theme_default','dark','2026-02-18 10:00:00',18),
(19,'language_default','ru','2026-02-19 10:00:00',19),
(20,'backup_schedule','0 2 * * *','2026-02-20 10:00:00',20),
(21,'audit_log_enabled','true','2026-02-21 10:00:00',21),
(22,'ip_whitelist_enabled','false','2026-02-22 10:00:00',22),
(23,'smtp_host','smtp.infrawatch.local','2026-02-23 10:00:00',23),
(24,'smtp_port','587','2026-02-24 10:00:00',24),
(25,'smtp_tls','true','2026-02-25 10:00:00',25),
(26,'ldap_server','ldap.infrawatch.local','2026-02-26 10:00:00',26),
(27,'ldap_base_dn','dc=infrawatch,dc=local','2026-02-27 10:00:00',27),
(28,'sso_enabled','false','2026-02-28 10:00:00',28),
(29,'webhook_retry_count','3','2026-03-01 10:00:00',29),
(30,'max_dashboard_widgets','12','2026-03-02 10:00:00',30),
(31,'chart_interpolation','linear','2026-03-03 10:00:00',31),
(32,'data_sampling_rate','10s','2026-03-04 10:00:00',32),
(33,'alert_sound_enabled','true','2026-03-05 10:00:00',33),
(34,'mobile_push_enabled','false','2026-03-06 10:00:00',34),
(35,'incident_escalation_min','15','2026-03-07 10:00:00',35),
(36,'sla_report_recipients','ops@infrawatch.local','2026-03-08 10:00:00',36),
(37,'csv_delimiter',',','2026-03-09 10:00:00',37),
(38,'date_format','YYYY-MM-DD','2026-03-10 10:00:00',38),
(39,'time_format','HH:mm:ss','2026-03-11 10:00:00',39),
(40,'max_query_timeout_sec','30','2026-03-12 10:00:00',40),
(41,'cache_ttl_sec','300','2026-03-13 10:00:00',41),
(42,'ui_pagination_size','25','2026-03-14 10:00:00',42),
(43,'auto_refresh_graphs','true','2026-03-15 10:00:00',43),
(44,'show_deprecated_metrics','false','2026-03-16 10:00:00',44),
(45,'alert_digest_hour','8','2026-03-17 10:00:00',45),
(46,'maintenance_blackout','false','2026-03-18 10:00:00',46),
(47,'log_level','info','2026-03-19 10:00:00',47),
(48,'db_pool_size','20','2026-03-20 10:00:00',48),
(49,'http_proxy_enabled','false','2026-03-21 10:00:00',49),
(50,'system_version','2.4.1','2026-03-22 10:00:00',50);
/*!40000 ALTER TABLE `system_settings` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `teams`
--

DROP TABLE IF EXISTS `teams`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `teams` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `lead_user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `lead_user_id` (`lead_user_id`),
  CONSTRAINT `1` FOREIGN KEY (`lead_user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `teams`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `teams` WRITE;
/*!40000 ALTER TABLE `teams` DISABLE KEYS */;
INSERT INTO `teams` VALUES
(1,'DevOps Alpha','Core infrastructure team',1),
(2,'DevOps Beta','Cloud migration team',2),
(3,'Network Ops','Routing and switching',3),
(4,'Security Ops','Firewall and compliance',4),
(5,'Database Team','RDBMS and NoSQL management',5),
(6,'Monitoring Squad','Alerting and dashboards',6),
(7,'Platform Eng','Kubernetes and containers',7),
(8,'Storage Ops','SAN and backup systems',8),
(9,'Edge Computing','IoT and remote nodes',9),
(10,'Automation Lab','CI/CD and IaC pipelines',10),
(11,'Support L1','First line response',11),
(12,'Support L2','Escalation handling',12),
(13,'Capacity Plan','Resource forecasting',13),
(14,'Compliance Audit','SLA and reporting',14),
(15,'Release Mgmt','Deployment coordination',15),
(16,'Incident Response','Major outage handling',16),
(17,'Performance Tuning','Query and system optimization',17),
(18,'Cloud Native','Serverless and microservices',18),
(19,'Legacy Systems','On-prem maintenance',19),
(20,'Research Dev','Proof of concept testing',20),
(21,'Vendor Liaison','Third-party integrations',21),
(22,'Training Unit','Onboarding and docs',22),
(23,'Disaster Recovery','Failover and backups',23),
(24,'Cost Optimization','Cloud billing and rightsizing',24),
(25,'Access Control','IAM and permissions',25),
(26,'Log Management','Centralized logging',26),
(27,'Patch Management','OS and firmware updates',27),
(28,'Hardware Ops','Physical server maintenance',28),
(29,'Virtualization','VMware and Hyper-V',29),
(30,'API Gateway','Service mesh and routing',30),
(31,'Data Pipeline','ETL and streaming',31),
(32,'Search Cluster','Elastic and indexing',32),
(33,'Cache Layer','Redis and memcached',33),
(34,'Message Queue','Kafka and RabbitMQ',34),
(35,'DNS Services','Internal and external resolution',35),
(36,'Load Balancing','HAProxy and Nginx',36),
(37,'Certificate Mgmt','TLS and PKI',37),
(38,'Backup Ops','Snapshot and archival',38),
(39,'Compliance Sec','GDPR and ISO audits',39),
(40,'Dev Tools','Internal developer platform',40),
(41,'SRE Team','Reliability engineering',41),
(42,'Observability','Tracing and metrics',42),
(43,'GitOps Flow','Declarative deployments',43),
(44,'Service Desk','Ticket routing',44),
(45,'Asset Tracking','Inventory and lifecycle',45),
(46,'Network Sec','IDS/IPS management',46),
(47,'Cloud FinOps','Budget and forecasting',47),
(48,'App Support','Business app maintenance',48),
(49,'QA Infra','Test environment provisioning',49),
(50,'Arch Review','Design and standards',50);
/*!40000 ALTER TABLE `teams` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('admin','engineer','viewer') NOT NULL DEFAULT 'viewer',
  `email` varchar(100) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES
(1,'admin_01','$2y$10$placeholder','admin','admin01@infrawatch.local','2026-01-10 08:00:00'),
(2,'admin_02','$2y$10$placeholder','admin','admin02@infrawatch.local','2026-01-10 08:05:00'),
(3,'eng_01','$2y$10$placeholder','engineer','eng01@infrawatch.local','2026-01-11 09:00:00'),
(4,'eng_02','$2y$10$placeholder','engineer','eng02@infrawatch.local','2026-01-11 09:05:00'),
(5,'eng_03','$2y$10$placeholder','engineer','eng03@infrawatch.local','2026-01-12 10:00:00'),
(6,'eng_04','$2y$10$placeholder','engineer','eng04@infrawatch.local','2026-01-12 10:05:00'),
(7,'eng_05','$2y$10$placeholder','engineer','eng05@infrawatch.local','2026-01-13 11:00:00'),
(8,'eng_06','$2y$10$placeholder','engineer','eng06@infrawatch.local','2026-01-13 11:05:00'),
(9,'eng_07','$2y$10$placeholder','engineer','eng07@infrawatch.local','2026-01-14 12:00:00'),
(10,'eng_08','$2y$10$placeholder','engineer','eng08@infrawatch.local','2026-01-14 12:05:00'),
(11,'eng_09','$2y$10$placeholder','engineer','eng09@infrawatch.local','2026-01-15 08:00:00'),
(12,'eng_10','$2y$10$placeholder','engineer','eng10@infrawatch.local','2026-01-15 08:05:00'),
(13,'eng_11','$2y$10$placeholder','engineer','eng11@infrawatch.local','2026-01-16 09:00:00'),
(14,'eng_12','$2y$10$placeholder','engineer','eng12@infrawatch.local','2026-01-16 09:05:00'),
(15,'eng_13','$2y$10$placeholder','engineer','eng13@infrawatch.local','2026-01-17 10:00:00'),
(16,'eng_14','$2y$10$placeholder','engineer','eng14@infrawatch.local','2026-01-17 10:05:00'),
(17,'eng_15','$2y$10$placeholder','engineer','eng15@infrawatch.local','2026-01-18 11:00:00'),
(18,'eng_16','$2y$10$placeholder','engineer','eng16@infrawatch.local','2026-01-18 11:05:00'),
(19,'eng_17','$2y$10$placeholder','engineer','eng17@infrawatch.local','2026-01-19 12:00:00'),
(20,'eng_18','$2y$10$placeholder','engineer','eng18@infrawatch.local','2026-01-19 12:05:00'),
(21,'eng_19','$2y$10$placeholder','engineer','eng19@infrawatch.local','2026-01-20 08:00:00'),
(22,'eng_20','$2y$10$placeholder','engineer','eng20@infrawatch.local','2026-01-20 08:05:00'),
(23,'eng_21','$2y$10$placeholder','engineer','eng21@infrawatch.local','2026-01-21 09:00:00'),
(24,'eng_22','$2y$10$placeholder','engineer','eng22@infrawatch.local','2026-01-21 09:05:00'),
(25,'eng_23','$2y$10$placeholder','engineer','eng23@infrawatch.local','2026-01-22 10:00:00'),
(26,'eng_24','$2y$10$placeholder','engineer','eng24@infrawatch.local','2026-01-22 10:05:00'),
(27,'eng_25','$2y$10$placeholder','engineer','eng25@infrawatch.local','2026-01-23 11:00:00'),
(28,'eng_26','$2y$10$placeholder','engineer','eng26@infrawatch.local','2026-01-23 11:05:00'),
(29,'eng_27','$2y$10$placeholder','engineer','eng27@infrawatch.local','2026-01-24 12:00:00'),
(30,'eng_28','$2y$10$placeholder','engineer','eng28@infrawatch.local','2026-01-24 12:05:00'),
(31,'eng_29','$2y$10$placeholder','engineer','eng29@infrawatch.local','2026-01-25 08:00:00'),
(32,'eng_30','$2y$10$placeholder','engineer','eng30@infrawatch.local','2026-01-25 08:05:00'),
(33,'eng_31','$2y$10$placeholder','engineer','eng31@infrawatch.local','2026-01-26 09:00:00'),
(34,'eng_32','$2y$10$placeholder','engineer','eng32@infrawatch.local','2026-01-26 09:05:00'),
(35,'eng_33','$2y$10$placeholder','engineer','eng33@infrawatch.local','2026-01-27 10:00:00'),
(36,'eng_34','$2y$10$placeholder','engineer','eng34@infrawatch.local','2026-01-27 10:05:00'),
(37,'eng_35','$2y$10$placeholder','engineer','eng35@infrawatch.local','2026-01-28 11:00:00'),
(38,'eng_36','$2y$10$placeholder','engineer','eng36@infrawatch.local','2026-01-28 11:05:00'),
(39,'eng_37','$2y$10$placeholder','engineer','eng37@infrawatch.local','2026-01-29 12:00:00'),
(40,'eng_38','$2y$10$placeholder','engineer','eng38@infrawatch.local','2026-01-29 12:05:00'),
(41,'viewer_01','$2y$10$placeholder','viewer','viewer01@infrawatch.local','2026-02-01 08:00:00'),
(42,'viewer_02','$2y$10$placeholder','viewer','viewer02@infrawatch.local','2026-02-01 08:05:00'),
(43,'viewer_03','$2y$10$placeholder','viewer','viewer03@infrawatch.local','2026-02-02 09:00:00'),
(44,'viewer_04','$2y$10$placeholder','viewer','viewer04@infrawatch.local','2026-02-02 09:05:00'),
(45,'viewer_05','$2y$10$placeholder','viewer','viewer05@infrawatch.local','2026-02-03 10:00:00'),
(46,'viewer_06','$2y$10$placeholder','viewer','viewer06@infrawatch.local','2026-02-03 10:05:00'),
(47,'viewer_07','$2y$10$placeholder','viewer','viewer07@infrawatch.local','2026-02-04 11:00:00'),
(48,'viewer_08','$2y$10$placeholder','viewer','viewer08@infrawatch.local','2026-02-04 11:05:00'),
(49,'viewer_09','$2y$10$placeholder','viewer','viewer09@infrawatch.local','2026-02-05 12:00:00'),
(50,'viewer_10','$2y$10$placeholder','viewer','viewer10@infrawatch.local','2026-02-05 12:05:00');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*M!100616 SET NOTE_VERBOSITY=@OLD_NOTE_VERBOSITY */;

-- Dump completed on 2026-06-08  8:06:58
