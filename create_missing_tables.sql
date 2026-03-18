-- Run this SQL in phpMyAdmin to create the required tables

-- Create lead_activities table
CREATE TABLE IF NOT EXISTS `lead_activities` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `lead_id` INT NOT NULL,
    `user_id` INT NOT NULL DEFAULT 1,
    `activity_type` VARCHAR(100) NOT NULL,
    `description` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_lead_id` (`lead_id`),
    INDEX `idx_created_at` (`created_at`)
);

-- Create lead_notes table
CREATE TABLE IF NOT EXISTS `lead_notes` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `lead_id` INT NOT NULL,
    `user_id` INT NOT NULL DEFAULT 1,
    `content` TEXT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_lead_id` (`lead_id`),
    INDEX `idx_created_at` (`created_at`)
);

-- Create lead_tasks table (if it doesn't exist)
CREATE TABLE IF NOT EXISTS `lead_tasks` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `lead_id` INT NOT NULL,
    `user_id` INT NOT NULL DEFAULT 1,
    `title` VARCHAR(255) NOT NULL,
    `description` TEXT,
    `priority` ENUM('Low', 'Medium', 'High') DEFAULT 'Medium',
    `due_date` DATETIME NULL,
    `is_completed` TINYINT(1) DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_lead_id` (`lead_id`),
    INDEX `idx_due_date` (`due_date`),
    INDEX `idx_created_at` (`created_at`)
);

-- Create users table (if it doesn't exist)
CREATE TABLE IF NOT EXISTS `users` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(50) NOT NULL UNIQUE,
    `email` VARCHAR(100) NOT NULL UNIQUE,
    `password` VARCHAR(255) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert a default user if none exists
INSERT IGNORE INTO `users` (`id`, `username`, `email`, `password`) 
VALUES (1, 'admin', 'admin@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi');