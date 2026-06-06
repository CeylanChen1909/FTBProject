-- Football forecast system schema

CREATE TABLE IF NOT EXISTS `t_user` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `username` VARCHAR(64) NOT NULL COMMENT '用户名',
  `password_hash` VARCHAR(128) NOT NULL COMMENT '密码哈希(SHA256)',
  `role` VARCHAR(32) NOT NULL DEFAULT 'USER' COMMENT '角色:USER/ADMIN',
  `status` VARCHAR(32) NOT NULL DEFAULT 'ACTIVE' COMMENT '状态:ACTIVE/DISABLED',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`),
  KEY `idx_role` (`role`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

CREATE TABLE IF NOT EXISTS `t_video_hub_item` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `title` VARCHAR(255) NOT NULL COMMENT '视频标题',
  `subtitle` VARCHAR(512) DEFAULT NULL COMMENT '视频副标题',
  `description` VARCHAR(2000) DEFAULT NULL COMMENT '视频描述',
  `cover_image` VARCHAR(1024) NOT NULL COMMENT '封面图',
  `video_url` VARCHAR(2048) NOT NULL COMMENT '外部视频链接',
  `platform` VARCHAR(64) NOT NULL COMMENT '平台来源',
  `league_name` VARCHAR(128) DEFAULT NULL COMMENT '联赛名称',
  `home_team_name` VARCHAR(128) DEFAULT NULL COMMENT '主队',
  `away_team_name` VARCHAR(128) DEFAULT NULL COMMENT '客队',
  `match_time` DATETIME DEFAULT NULL COMMENT '比赛时间',
  `video_type` VARCHAR(64) NOT NULL DEFAULT 'HIGHLIGHT' COMMENT '类型:HIGHLIGHT/REPLAY/INTERVIEW/OTHER',
  `is_hot` TINYINT NOT NULL DEFAULT 0 COMMENT '是否热门',
  `is_featured` TINYINT NOT NULL DEFAULT 0 COMMENT '是否推荐',
  `sort_order` INT NOT NULL DEFAULT 0 COMMENT '排序',
  `status` VARCHAR(32) NOT NULL DEFAULT 'PUBLISHED' COMMENT '状态:PUBLISHED/DRAFT/HIDDEN',
  `created_by` BIGINT DEFAULT NULL COMMENT '创建人',
  `updated_by` BIGINT DEFAULT NULL COMMENT '更新人',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_status_sort` (`status`, `sort_order`, `created_at`),
  KEY `idx_league_name` (`league_name`),
  KEY `idx_platform` (`platform`),
  KEY `idx_video_type` (`video_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='视频聚合内容表';

CREATE TABLE IF NOT EXISTS `t_system_config` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `config_key` VARCHAR(128) NOT NULL COMMENT '配置键',
  `config_value` TEXT COMMENT '配置值',
  `config_desc` VARCHAR(255) DEFAULT NULL COMMENT '描述',
  `updated_by` BIGINT DEFAULT NULL COMMENT '更新人ID',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_config_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统配置表';

-- ... existing schema continues unchanged ...
