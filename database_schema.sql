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

-- Update tasks table to include lead_id if not exists
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS lead_id INT NULL AFTER contact_id;
ALTER TABLE tasks ADD INDEX IF NOT EXISTS idx_lead_id (lead_id);