-- 快速初始化脚本 - 仅创建必要的表结构
-- 请先确保已创建seckill数据库

CREATE DATABASE IF NOT EXISTS seckill DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE seckill;

-- 秒杀商品表
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

-- 秒杀订单表
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

SELECT '数据库表创建成功!' AS message;
