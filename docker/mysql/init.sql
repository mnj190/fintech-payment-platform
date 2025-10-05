-- 결제 테이블
CREATE TABLE IF NOT EXISTS payments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    payment_key VARCHAR(200) NOT NULL UNIQUE COMMENT 'PG사 결제 키',
    order_id VARCHAR(200) NOT NULL COMMENT '주문 ID',
    idempotency_key VARCHAR(200) NOT NULL UNIQUE COMMENT '멱등성 키',
    user_id BIGINT NOT NULL COMMENT '사용자 ID',
    amount DECIMAL(15, 2) NOT NULL COMMENT '결제 금액',
    payment_method VARCHAR(50) NOT NULL COMMENT '결제 수단',
    status VARCHAR(50) NOT NULL COMMENT '결제 상태',
    pg_response JSON COMMENT 'PG사 응답 데이터',
    approved_at DATETIME COMMENT '승인 시간',
    canceled_at DATETIME COMMENT '취소 시간',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_order_id (order_id),
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='결제 정보';

-- 결제 이벤트 아웃박스 테이블 (Transactional Outbox Pattern)
CREATE TABLE IF NOT EXISTS payment_outbox (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    aggregate_id VARCHAR(200) NOT NULL COMMENT '집합 루트 ID',
    aggregate_type VARCHAR(100) NOT NULL COMMENT '집합 루트 타입',
    event_type VARCHAR(100) NOT NULL COMMENT '이벤트 타입',
    payload JSON NOT NULL COMMENT '이벤트 페이로드',
    published BOOLEAN DEFAULT FALSE COMMENT '발행 여부',
    published_at DATETIME COMMENT '발행 시간',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_published (published),
    INDEX idx_aggregate_id (aggregate_id),
    INDEX idx_event_type (event_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='이벤트 아웃박스';

-- 결제 히스토리 테이블 (이벤트 소싱)
CREATE TABLE IF NOT EXISTS payment_events (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    payment_id BIGINT NOT NULL COMMENT '결제 ID',
    event_type VARCHAR(100) NOT NULL COMMENT '이벤트 타입',
    previous_status VARCHAR(50) COMMENT '이전 상태',
    current_status VARCHAR(50) COMMENT '현재 상태',
    payload JSON NOT NULL COMMENT '이벤트 상세',
    created_by VARCHAR(100) COMMENT '생성자',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_payment_id (payment_id),
    INDEX idx_event_type (event_type),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='결제 이벤트 히스토리';

-- PG 웹훅 로그 테이블
CREATE TABLE IF NOT EXISTS pg_webhook_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    payment_key VARCHAR(200) NOT NULL COMMENT 'PG사 결제 키',
    webhook_type VARCHAR(100) NOT NULL COMMENT '웹훅 타입',
    payload JSON NOT NULL COMMENT '웹훅 페이로드',
    signature VARCHAR(500) COMMENT '웹훅 서명',
    verified BOOLEAN DEFAULT FALSE COMMENT '검증 여부',
    processed BOOLEAN DEFAULT FALSE COMMENT '처리 여부',
    error_message TEXT COMMENT '에러 메시지',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_at DATETIME COMMENT '처리 시간',
    INDEX idx_payment_key (payment_key),
    INDEX idx_processed (processed),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PG 웹훅 로그';

-- 결제 재시도 로그 테이블
CREATE TABLE IF NOT EXISTS payment_retry_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    payment_id BIGINT NOT NULL COMMENT '결제 ID',
    retry_count INT NOT NULL DEFAULT 0 COMMENT '재시도 횟수',
    reason VARCHAR(500) COMMENT '재시도 사유',
    error_message TEXT COMMENT '에러 메시지',
    next_retry_at DATETIME COMMENT '다음 재시도 시간',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_payment_id (payment_id),
    INDEX idx_next_retry_at (next_retry_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='결제 재시도 로그';
