-- ==============================================================================
-- NAKHL & NAHL — CORE DATABASE BUILD v1.0
-- Migration: 001_extensions.sql
-- Purpose: Gerekli temel PostgreSQL eklentilerini etkinleştirir.
-- ==============================================================================

-- UUID üretimi için (v4)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Şifreleme ve kriptografik karma işlemleri için
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Büyük/küçük harf duyarsız metin alanları için (e-posta, kodlar vb.)
CREATE EXTENSION IF NOT EXISTS "citext";
