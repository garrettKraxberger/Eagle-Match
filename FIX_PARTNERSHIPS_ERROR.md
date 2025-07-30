# 🔧 Fix Partnerships Table Error

## The Problem
You're getting this error because the `partnerships` table doesn't exist in your Supabase database yet:

```
PostgrestException: Could not find a relationship between 'partnerships' and 'profiles'
```

## ✅ Solution (2 Steps)

### Step 1: Go to Supabase Dashboard
1. Open your Supabase project dashboard
2. Navigate to **SQL Editor** (in the left sidebar)

### Step 2: Run the SQL Setup Script
1. Click **"New Query"**
2. Copy and paste the contents of `setup_partnerships_table.sql` into the editor
3. Click **"Run"** button

## 🎯 What This Does

The SQL script will:
- ✅ Create the `partnerships` table with proper foreign keys
- ✅ Set up Row Level Security (RLS) policies
- ✅ Create database indexes for performance
- ✅ Add sample data for testing (optional)

## 🔍 Verify It Worked

After running the SQL:
1. Go back to your Eagle Match app
2. Navigate to the **Duos** tab
3. Pull down to refresh or tap "Retry"
4. You should now see "No partnerships yet" instead of the error

## 📱 How Partnerships Work

Once set up:
- **Automatic Creation**: Partnerships are created when users play matches together
- **Statistics Tracking**: Matches played, wins, win percentage
- **Star Favorites**: Mark preferred partners with stars
- **Smart Display**: Starred partnerships shown at the top

## 🚀 Next Steps

After the table is created:
1. Play some matches with other users
2. Partnerships will automatically appear in the Duos screen
3. You can star your favorite partners
4. View match statistics and win rates

That's it! The Duos screen will now be fully functional with real Supabase data! 🎉
