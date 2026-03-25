-- Drop the table if it exists to start fresh
DROP TABLE IF EXISTS users;

-- Create users table with the correct schema
CREATE TABLE users (
    user_Id INT AUTO_INCREMENT PRIMARY KEY,
    userName VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    user_secret VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    phone VARCHAR(20),
    country VARCHAR(50),
    company_address VARCHAR(255),
    timezone VARCHAR(50),
    meta TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL
);

-- Insert default admin user (password: admin123)
INSERT INTO users (userName, email, user_secret, full_name)
VALUES ('admin', 'admin@example.com', '$2y$10$tZnxJxgRHmGjPW2XjPjoGOCT8S5ro9jRaOZ0FMHUU0Qzq/NtDTR9S', 'Admin User');
