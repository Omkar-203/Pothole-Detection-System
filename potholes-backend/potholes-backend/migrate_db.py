#!/usr/bin/env python3
"""
Database migration script to add new columns to pothole_requests table.
Run this script to update the database schema.
"""

from sqlalchemy import create_engine, Column, String, text
from database import SQLALCHEMY_DATABASE_URL

def run_migration():
    engine = create_engine(SQLALCHEMY_DATABASE_URL)

    with engine.connect() as conn:
        # Add status column with default value 'pending'
        try:
            conn.execute(text("ALTER TABLE pothole_requests ADD COLUMN status VARCHAR(20) DEFAULT 'pending'"))
            print("✅ Added 'status' column to pothole_requests table")
        except Exception as e:
            print(f"⚠️  Status column might already exist: {e}")

        # Add street_name column
        try:
            conn.execute(text("ALTER TABLE pothole_requests ADD COLUMN street_name VARCHAR(100)"))
            print("✅ Added 'street_name' column to pothole_requests table")
        except Exception as e:
            print(f"⚠️  Street_name column might already exist: {e}")

        # Update existing records to have 'pending' status if they don't have one
        try:
            conn.execute(text("UPDATE pothole_requests SET status = 'pending' WHERE status IS NULL"))
            print("✅ Updated existing records with default status")
        except Exception as e:
            print(f"⚠️  Could not update existing records: {e}")

        conn.commit()

    print("🎉 Migration completed successfully!")

if __name__ == "__main__":
    run_migration()