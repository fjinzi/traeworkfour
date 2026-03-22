-- =============================================
-- 秒杀商品管理数据库脚本
-- 数据库版本: MySQL 8.0.32
-- 创建时间: 2024
-- =============================================

-- 创建数据库
CREATE DATABASE IF NOT EXISTS seckill DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE seckill;

-- =============================================
-- 1. 秒杀商品表
-- =============================================
DROP TABLE IF EXISTS seckill_product;

CREATE TABLE seckill_product (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '商品ID',
    name VARCHAR(100) NOT NULL COMMENT '商品名称',
    stock INT NOT NULL DEFAULT 0 COMMENT '库存数量',
    price DECIMAL(10, 2) NOT NULL COMMENT '秒杀价格',
    original_price DECIMAL(10, 2) DEFAULT NULL COMMENT '原价',
    description VARCHAR(500) DEFAULT NULL COMMENT '商品描述',
    image_url VARCHAR(255) DEFAULT NULL COMMENT '商品图片URL',
    start_time DATETIME NOT NULL COMMENT '秒杀开始时间',
    end_time DATETIME NOT NULL COMMENT '秒杀结束时间',
    status TINYINT NOT NULL DEFAULT 0 COMMENT '状态: 0-未开始, 1-进行中, 2-已结束, 3-已下架',
    version INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (id),
    INDEX idx_start_time (start_time),
    INDEX idx_end_time (end_time),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='秒杀商品表';

-- =============================================
-- 2. 秒杀订单表
-- =============================================
DROP TABLE IF EXISTS seckill_order;

CREATE TABLE seckill_order (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '订单ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    product_id BIGINT NOT NULL COMMENT '商品ID',
    product_name VARCHAR(100) NOT NULL COMMENT '商品名称',
    price DECIMAL(10, 2) NOT NULL COMMENT '购买价格',
    quantity INT NOT NULL DEFAULT 1 COMMENT '购买数量',
    status TINYINT NOT NULL DEFAULT 0 COMMENT '订单状态: 0-待支付, 1-已支付, 2-已取消, 3-已退款',
    order_no VARCHAR(64) NOT NULL COMMENT '订单号',
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_order_no (order_no),
    INDEX idx_user_id (user_id),
    INDEX idx_product_id (product_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='秒杀订单表';

-- =============================================
-- 3. 初始化测试数据
-- =============================================
INSERT INTO seckill_product (name, stock, price, original_price, description, start_time, end_time, status) VALUES
('iPhone 15 Pro Max', 100, 7999.00, 9999.00, '苹果最新旗舰手机，A17 Pro芯片，钛金属设计', DATE_ADD(NOW(), INTERVAL -1 HOUR), DATE_ADD(NOW(), INTERVAL 23 HOUR), 1),
('华为Mate 60 Pro', 200, 5999.00, 6999.00, '华为旗舰手机，麒麟9000S芯片，卫星通信', DATE_ADD(NOW(), INTERVAL -1 HOUR), DATE_ADD(NOW(), INTERVAL 23 HOUR), 1),
('小米14 Ultra', 150, 5499.00, 6499.00, '小米影像旗舰，徕卡光学镜头', DATE_ADD(NOW(), INTERVAL 1 HOUR), DATE_ADD(NOW(), INTERVAL 25 HOUR), 0),
('MacBook Pro 14', 50, 12999.00, 14999.00, 'M3 Pro芯片，专业级笔记本电脑', DATE_ADD(NOW(), INTERVAL 2 HOUR), DATE_ADD(NOW(), INTERVAL 26 HOUR), 0);

-- =============================================
-- 4. 创建视图 - 活动中的秒杀商品
-- =============================================
DROP VIEW IF EXISTS v_active_seckill_products;

CREATE VIEW v_active_seckill_products AS
SELECT 
    id,
    name,
    stock,
    price,
    original_price,
    description,
    image_url,
    start_time,
    end_time,
    status,
    CASE 
        WHEN NOW() < start_time THEN '未开始'
        WHEN NOW() BETWEEN start_time AND end_time THEN '进行中'
        ELSE '已结束'
    END AS activity_status
FROM seckill_product
WHERE status = 1
  AND NOW() BETWEEN start_time AND end_time;

-- =============================================
-- 5. 存储过程 - 扣减库存
-- =============================================
DROP PROCEDURE IF EXISTS sp_decrease_stock;

DELIMITER //
CREATE PROCEDURE sp_decrease_stock(
    IN p_product_id BIGINT,
    IN p_quantity INT,
    OUT p_result INT
)
BEGIN
    DECLARE v_current_stock INT;
    DECLARE v_version INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_result = -1;
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    SELECT stock, version INTO v_current_stock, v_version
    FROM seckill_product WHERE id = p_product_id FOR UPDATE;
    
    IF v_current_stock >= p_quantity THEN
        UPDATE seckill_product 
        SET stock = stock - p_quantity, version = version + 1
        WHERE id = p_product_id AND version = v_version;
        
        IF ROW_COUNT() > 0 THEN
            SET p_result = 1;
            COMMIT;
        ELSE
            SET p_result = 0;
            ROLLBACK;
        END IF;
    ELSE
        SET p_result = 0;
        ROLLBACK;
    END IF;
END //
DELIMITER ;

-- =============================================
-- 6. 存储过程 - 自动更新商品状态
-- =============================================
DROP PROCEDURE IF EXISTS sp_update_product_status;

DELIMITER //
CREATE PROCEDURE sp_update_product_status()
BEGIN
    UPDATE seckill_product 
    SET status = 1 
    WHERE status = 0 AND NOW() >= start_time AND NOW() < end_time;
    
    UPDATE seckill_product 
    SET status = 2 
    WHERE status = 1 AND NOW() >= end_time;
END //
DELIMITER ;

-- =============================================
-- 7. 事件 - 每分钟自动更新商品状态
-- =============================================
SET GLOBAL event_scheduler = ON;

DROP EVENT IF EXISTS evt_update_product_status;

CREATE EVENT evt_update_product_status
ON SCHEDULE EVERY 1 MINUTE
DO CALL sp_update_product_status();

-- =============================================
-- 8. 查询验证
-- =============================================
SELECT '数据库初始化完成!' AS message;
SELECT * FROM seckill_product;
