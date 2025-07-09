# Supabase Setup Guide

This guide will help you set up Supabase for the Future Self backend.

## 1. Create Supabase Project

1. **Visit [Supabase](https://supabase.com)** and sign up/login
2. **Create a new project**:
   - Click "New Project"
   - Choose your organization
   - Enter project name: `future-self`
   - Choose a database password (save this!)
   - Select a region closest to your users
   - Click "Create new project"

3. **Wait for setup** (usually takes 2-3 minutes)

## 2. Get Your Project Credentials

Once your project is ready:

1. **Go to Settings → API**
2. **Copy the following values**:
   ```
   Project URL: https://your-project-id.supabase.co
   Anon Key: your-anon-key
   Service Role Key: your-service-role-key (keep this secret!)
   ```

3. **Update your `.env` file**:
   ```env
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   SUPABASE_SERVICE_KEY=your-service-role-key
   ```

## 3. Set Up Database Schema

### Option A: Using Supabase SQL Editor (Recommended)

1. **Go to SQL Editor** in your Supabase dashboard
2. **Create a new query**
3. **Copy and paste** the contents of `backend/database/schema.sql`
4. **Run the query** to create all tables and policies

### Option B: Using Database URL

1. **Go to Settings → Database**
2. **Copy the Connection String**:
   ```
   postgresql://postgres:[YOUR-PASSWORD]@db.your-project-id.supabase.co:5432/postgres
   ```
3. **Update your `.env` file**:
   ```env
   DATABASE_URL=postgresql://postgres:[YOUR-PASSWORD]@db.your-project-id.supabase.co:5432/postgres
   ```

## 4. Configure Authentication

1. **Go to Authentication → Settings**
2. **Enable Email confirmation** (recommended)
3. **Configure redirects** if needed for your frontend
4. **Set up providers** you want to use (optional):
   - Google OAuth
   - GitHub OAuth
   - Apple OAuth

## 5. Set Up Row Level Security (RLS)

The schema already includes RLS policies, but verify they're active:

1. **Go to Authentication → Policies**
2. **Check that policies exist** for all tables
3. **Verify users can only access their own data**

## 6. Configure Storage (Optional)

For file uploads (profile photos, voice messages):

1. **Go to Storage**
2. **Create buckets**:
   ```sql
   -- Profile photos
   INSERT INTO storage.buckets (id, name, public) VALUES ('profile-photos', 'profile-photos', true);
   
   -- Future self photos
   INSERT INTO storage.buckets (id, name, public) VALUES ('future-self-photos', 'future-self-photos', true);
   
   -- Voice messages (private)
   INSERT INTO storage.buckets (id, name, public) VALUES ('voice-messages', 'voice-messages', false);
   ```

3. **Set up storage policies**:
   ```sql
   -- Allow users to upload their own files
   CREATE POLICY "Users can upload own files" ON storage.objects
   FOR INSERT WITH CHECK (auth.uid()::text = (storage.foldername(name))[1]);
   
   -- Allow users to view their own files
   CREATE POLICY "Users can view own files" ON storage.objects
   FOR SELECT USING (auth.uid()::text = (storage.foldername(name))[1]);
   ```

## 7. Test Your Setup

1. **Start your backend server**:
   ```bash
   cd backend
   python start_dev.py
   ```

2. **Check health endpoints**:
   ```bash
   # Basic health check
   curl http://localhost:8000/api/v1/health/
   
   # Database health
   curl http://localhost:8000/api/v1/health/database
   
   # Supabase health
   curl http://localhost:8000/api/v1/health/supabase
   ```

3. **Verify database connection** in the logs

## 8. Environment Variables Reference

Complete `.env` file example:

```env
# Database Configuration
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_KEY=your-service-role-key
DATABASE_URL=postgresql://postgres:your-password@db.your-project-id.supabase.co:5432/postgres

# Security
SECRET_KEY=your-super-secret-jwt-key-here-make-it-long-and-random
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Environment
ENVIRONMENT=development
DEBUG=True
API_V1_STR=/api/v1

# External APIs (optional for now)
OPENAI_API_KEY=your-openai-api-key
OLLAMA_BASE_URL=http://localhost:11434

# Redis Configuration (for future background tasks)
REDIS_URL=redis://localhost:6379/0

# CORS Settings
CORS_ORIGINS=["http://localhost:3000", "http://localhost:8080"]

# File Upload
MAX_UPLOAD_SIZE=10485760  # 10MB
UPLOAD_DIR=./uploads

# Logging
LOG_LEVEL=INFO
LOG_FILE=./logs/app.log
```

## 9. Troubleshooting

### Connection Issues
- **Check your credentials** are correct
- **Verify your IP is allowed** (Supabase allows all by default)
- **Ensure your project is not paused**

### Schema Issues
- **Check the SQL Editor logs** for any errors
- **Verify all tables were created** in the Table Editor
- **Check RLS policies are active**

### Authentication Issues
- **Verify Supabase Auth is enabled**
- **Check your JWT secret** matches between Supabase and your app
- **Ensure RLS policies allow proper access**

## 10. Next Steps

Once Supabase is set up:

1. **Test user registration** via the API
2. **Implement authentication** in your endpoints
3. **Test onboarding data storage**
4. **Set up AI integration** for chat functionality
5. **Configure background tasks** for daily messages

## 11. Production Considerations

For production deployment:

1. **Use environment variables** instead of hardcoded values
2. **Set up database backups**
3. **Configure proper CORS origins**
4. **Enable database connection pooling**
5. **Set up monitoring and alerting**
6. **Use service role key securely**
7. **Configure rate limiting**
8. **Set up SSL/TLS properly**

## 12. Useful Supabase SQL Queries

```sql
-- Check all tables
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';

-- Check user count
SELECT COUNT(*) FROM auth.users;

-- Check onboarding completion rate
SELECT 
  COUNT(*) as total_users,
  COUNT(CASE WHEN is_complete THEN 1 END) as completed_onboarding,
  ROUND(COUNT(CASE WHEN is_complete THEN 1 END) * 100.0 / COUNT(*), 2) as completion_rate
FROM onboarding_data;

-- Check recent chat activity
SELECT 
  u.email,
  COUNT(cm.id) as message_count,
  MAX(cm.created_at) as last_message
FROM users u
LEFT JOIN chat_messages cm ON u.id = cm.user_id
GROUP BY u.id, u.email
ORDER BY last_message DESC;
``` 