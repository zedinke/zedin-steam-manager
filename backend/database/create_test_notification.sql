-- First, apply the schema if not done yet
-- Run this in Supabase SQL Editor

-- Create test notification for geleako@gmail.com
INSERT INTO notifications (user_id, title, message, type, read)
SELECT 
    id,
    '🎉 Teszt Értesítés',
    'Ez egy teszt értesítés a Module 1.5 notification rendszerből! Gratulálunk, minden működik! 🚀',
    'success',
    false
FROM auth.users 
WHERE email = 'geleako@gmail.com';

-- Verify the notification was created
SELECT 
    n.id,
    n.title,
    n.message,
    n.type,
    n.read,
    n.created_at,
    u.email
FROM notifications n
JOIN auth.users u ON n.user_id = u.id
WHERE u.email = 'geleako@gmail.com'
ORDER BY n.created_at DESC
LIMIT 5;
