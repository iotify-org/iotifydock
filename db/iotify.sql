CREATE TABLE `mqtt_user` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(100) DEFAULT NULL,
  `password` varchar(100) DEFAULT NULL,
  `is_superuser` tinyint(1) DEFAULT '0',
  `created` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `user_id` int(11) DEFAULT NULL,
  `device_id` varchar(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `mqtt_username` (`username`)
) ENGINE=MyISAM AUTO_INCREMENT=129 DEFAULT CHARSET=utf8;


CREATE TABLE `mqtt_acl` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `allow` int(1) DEFAULT NULL COMMENT '0: deny, 1: allow',
  `access` int(2) NOT NULL COMMENT '1: subscribe, 2: publish, 3: pubsub',
  `topic` varchar(100) NOT NULL DEFAULT '' COMMENT 'Topic Filter',
  `mqtt_user_id` int(11) NOT NULL,
  `ipaddr` varchar(60) DEFAULT NULL,
  `clientid` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=267 DEFAULT CHARSET=utf8;

CREATE or REPLACE view `mqtt_user_acl`
AS SELECT
   `mqtt_user`.`id` AS `id`,
   `mqtt_user`.`username` AS `username`,
   `mqtt_user`.`password` AS `password`,
   `mqtt_user`.`is_superuser` AS `is_superuser`,
   `mqtt_user`.`created` AS `created`,
   `mqtt_user`.`user_id` AS `user_id`,
   `mqtt_user`.`device_id` AS `device_id`,
   `mqtt_acl`.`allow` AS `allow`,
   `mqtt_acl`.`access` AS `access`,
   `mqtt_acl`.`topic` AS `topic`,
   `mqtt_acl`.`mqtt_user_id` AS `mqtt_user_id`,
   `mqtt_acl`.`ipaddr` AS `ipaddr`,
   `mqtt_acl`.`clientid` AS `clientid`
FROM (`mqtt_user` join `mqtt_acl` on((`mqtt_user`.`id` = `mqtt_acl`.`mqtt_user_id`)));
