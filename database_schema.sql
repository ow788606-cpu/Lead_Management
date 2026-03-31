-- Activities table for lead activities
CREATE TABLE IF NOT EXISTS activities (
    id INT AUTO_INCREMENT PRIMARY KEY,
    lead_id INT NOT NULL,
    user_id INT NOT NULL,
    type VARCHAR(50) DEFAULT 'activity',
    title VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_lead_user (lead_id, user_id),
    INDEX idx_created_at (created_at)
);

-- Notes table for lead notes
CREATE TABLE IF NOT EXISTS notes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    lead_id INT NOT NULL,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_lead_user (lead_id, user_id),
    INDEX idx_created_at (created_at)
);

-- Task details table for task comments, attachments, collaborators, activity
CREATE TABLE IF NOT EXISTS task_details (
    id INT AUTO_INCREMENT PRIMARY KEY,
    task_id INT NOT NULL,
    user_id INT NOT NULL,
    task_source VARCHAR(32) NOT NULL DEFAULT 'tasks',
    comments LONGTEXT NULL,
    attachments LONGTEXT NULL,
    collaborators LONGTEXT NULL,
    activities LONGTEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uniq_task_user_source (task_id, user_id, task_source),
    INDEX idx_task_user (task_id, user_id),
    INDEX idx_task_user_source (task_id, user_id, task_source)
);

-- Task notifications table for per-user read/unread state
CREATE TABLE IF NOT EXISTS task_notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    task_id INT NOT NULL,
    user_id INT NOT NULL,
    task_source VARCHAR(32) NOT NULL DEFAULT 'tasks',
    title VARCHAR(255) NOT NULL,
    message TEXT NULL,
    is_read TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_task_user (task_id, user_id),
    INDEX idx_user_read (user_id, is_read),
    INDEX idx_created_at (created_at)
);

-- Update tasks table to include lead_id if not exists
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS lead_id INT NULL AFTER contact_id;
ALTER TABLE tasks ADD INDEX IF NOT EXISTS idx_lead_id (lead_id);
