-- Migration: Add phone_number column to users table
-- Run this if you have an existing database

ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS phone_number VARCHAR(20);

-- Add comment for documentation
COMMENT ON COLUMN public.users.phone_number IS 'User phone number (optional)'; 