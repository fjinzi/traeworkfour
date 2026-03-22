-- =============================================
-- 用户表快速初始化脚本
-- 数据库版本: MySQL 8.0.32
-- =============================================

USE seckill;

-- 删除旧表（如果存在）
DROP TABLE IF EXISTS sys_user;

-- 创建用户表
CREATE TABLE sys_user (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '用户ID',
    username VARCHAR(50) NOT NULL COMMENT '用户名',
    password VARCHAR(100) NOT NULL COMMENT '密码',
    nickname VARCHAR(50) DEFAULT NULL COMMENT '昵称',
    email VARCHAR(100) DEFAULT NULL COMMENT '邮箱',
    phone VARCHAR(20) DEFAULT NULL COMMENT '手机号',
    role_type TINYINT NOT NULL DEFAULT 0 COMMENT '角色类型: 0-普通用户, 1-管理员',
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    is_deleted TINYINT NOT NULL DEFAULT 0 COMMENT '是否删除: 0-未删除, 1-已删除',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_username (username),
    INDEX idx_role_type (role_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- 插入管理员账户 (密码: admin123)
-- BCrypt加密后的密码
INSERT INTO sys_user (username, password, nickname, role_type) VALUES
('admin', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5EH', '系统管理员', 1);

-- 插入测试用户 (密码: user123)
INSERT INTO sys_user (username, password, nickname, role_type) VALUES
('testuser', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5EH', '测试用户', 0);

SELECT '用户表初始化完成!' AS message;
SELECT id, username, nickname, role_type, is_deleted FROM sys_user;
