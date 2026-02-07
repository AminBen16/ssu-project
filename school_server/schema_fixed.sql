-- Enable foreign keys (safe even if you don't define them yet)
PRAGMA foreign_keys = ON;

-- =========================
-- USERS
-- =========================
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'parent',
    first_name TEXT,
    last_name TEXT,
    profile_picture_url TEXT,
    created_at DATETIME NOT NULL DEFAULT datetime('now'),
    updated_at DATETIME NOT NULL DEFAULT datetime('now')
);

-- =========================
-- STUDENTS
-- =========================
CREATE TABLE IF NOT EXISTS students (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    date_of_birth DATE NOT NULL,
    class_id INTEGER NOT NULL,
    admission_date DATE NOT NULL DEFAULT date('now'),
    created_at DATETIME NOT NULL DEFAULT datetime('now'),
    updated_at DATETIME NOT NULL DEFAULT datetime('now')
);

-- =========================
-- EXAMS
-- =========================
CREATE TABLE IF NOT EXISTS exams (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    class_id INTEGER NOT NULL,
    subject_id INTEGER NOT NULL,
    exam_date DATE NOT NULL,
    max_marks INTEGER NOT NULL,
    created_at DATETIME NOT NULL DEFAULT datetime('now'),
    updated_at DATETIME NOT NULL DEFAULT datetime('now')
);

-- =========================
-- FEE STRUCTURES
-- =========================
CREATE TABLE IF NOT EXISTS fees (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    student_id INTEGER NOT NULL,
    amount REAL NOT NULL,
    due_date DATE NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at DATETIME NOT NULL DEFAULT datetime('now'),
    updated_at DATETIME NOT NULL DEFAULT datetime('now')
);

-- =========================
-- STAFF PAYMENTS
-- =========================
CREATE TABLE IF NOT EXISTS staff_payments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    staff_id INTEGER NOT NULL,
    school_id INTEGER NOT NULL,
    amount REAL NOT NULL,
    payment_date DATE NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    amount_paid NUMERIC NOT NULL,
    month TEXT NOT NULL,
    year INTEGER NOT NULL,
    payment_date DATETIME NOT NULL DEFAULT datetime('now'),
    recorded_by_id INTEGER NOT NULL,
    recorded_by_name TEXT,
    created_at DATETIME NOT NULL DEFAULT datetime('now'),
    updated_at DATETIME NOT NULL DEFAULT datetime('now')
);

-- Create indexes after all tables are created
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_students_class_id ON students(class_id);
CREATE INDEX IF NOT EXISTS idx_exams_class_id ON exams(class_id);
CREATE INDEX IF NOT EXISTS idx_fees_student_id ON fees(student_id);
CREATE INDEX IF NOT EXISTS idx_staff_payments_staff_id ON staff_payments(staff_id);
CREATE INDEX IF NOT EXISTS idx_staff_payments_school_id ON staff_payments(school_id);
