# Module 1.5 - Token & Notification System Backend

## ✅ Elkészült (2025-01-XX)

### Backend Komponensek:

1. **Database Schema** (`backend/database/tokens_schema.sql`)
   - `tokens` tábla: token_code, generated_by, assigned_to, status, expires_at
   - `notifications` tábla: user_id, title, message, type, read, link
   - RLS policies: role-based access (manager_admin, server_admin, user)
   - Indexek: performance optimalizálás
   - Triggers: automatic updated_at timestamp

2. **API Endpoints** (`backend/routers/tokens.py`)
   - `POST /api/tokens/generate` - Token generálás (Manager Admin only)
   - `POST /api/tokens/activate` - Token aktiválás + role upgrade
   - `GET /api/tokens/my` - Saját tokenek lekérése
   - `GET /api/tokens/all` - Összes token (Manager Admin only)
   - `GET /api/notifications` - Értesítések lekérése
   - `PATCH /api/notifications/:id/read` - Értesítés olvasottnak jelölése
   - `GET /api/notifications/unread-count` - Olvasatlan értesítések száma

3. **Email Templates** (`backend/services/email_service.py`)
   - `send_token_email()` - Token generálás email (Hungarian)
   - `send_expiry_notification()` - Lejárat figyelmeztető email (Hungarian)
   - Beautiful gradient design, responsive

## 📋 Következő Lépések (Frontend):

1. SQL séma alkalmazása Supabase-ben
2. Frontend komponensek készítése:
   - Token Generation Page (Manager Admin)
   - Token Activation Page (User)
   - Notification Icon + Panel (AppBar)
   - Token Expiration Widget (Server Admin Dashboard)
3. Background task: Automatic expiry notifications (5 days before)

## 🎯 Requirements Mapping:

- ✅ Token generálás csak Manager Admin-nak
- ✅ Assigned_to field server_admin és user role-oknak
- ✅ Email + notification integration ready
- ✅ Token activation + role upgrade endpoint
- ✅ Database storage with RLS policies
- ⏳ Dashboard widget (frontend)
- ⏳ 5-day advance notification (background task)
