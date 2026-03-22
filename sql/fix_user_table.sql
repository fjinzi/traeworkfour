-- =============================================
-- 修复用户表结构脚本
-- 解决 Unknown column 'role_type' in 'field list' 错误
-- =============================================

USE seckill;

-- 检查表是否存在
SELECT '检查 sys_user 表结构' AS message;

-- 尝试添加 role_type 列（如果不存在）
ALTER TABLE sys_user 
ADD COLUMN IF NOT EXISTS role_type TINYINT NOT NULL DEFAULT 0 COMMENT '角色类型: 0-普通用户, 1-管理员' AFTER phone;

-- 如果列名是 role 而不是 role_type，重命名它（为了兼容）
SET @col_exists := (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'seckill' 
      AND TABLE_NAME = 'sys_user' 
      AND COLUMN_NAME = 'role'
);

SET @sql := IF(@col_exists > 0,
    'ALTER TABLE sys_user CHANGE COLUMN role role_type TINYINT NOT NULL DEFAULT 0 COMMENT ''角色类型: 0-普通用户, 1-管理员''',
    'SELECT ''列 role 不存在，无需重命名'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 显示最终表结构
DESCRIBE sys_user;

SELECT '用户表结构修复完成!' AS message;
