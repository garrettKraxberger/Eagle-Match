# Duos Screen Setup Instructions

## Database Setup

1. **Run the partnerships table SQL:**
   - Go to your Supabase dashboard
   - Navigate to the SQL Editor
   - Run the contents of `create_partnerships_table.sql`

2. **The partnerships table will:**
   - Automatically track partnerships when users play matches together
   - Store match statistics (games played, wins, win percentage)
   - Allow users to star/favorite partnerships
   - Support nicknames for partnerships

## Features Implemented

### ✅ **Real Data Integration:**
- Fetches actual partnerships from Supabase database
- Shows real match statistics and win rates
- Updates automatically when matches are played

### ✅ **Partnership Management:**
- **Star/Unstar**: Mark favorite partners with star icon
- **Unlink**: Remove partnerships (sets status to inactive)
- **Statistics**: Shows matches played, wins, and win percentage
- **Nicknames**: Support for custom partnership names

### ✅ **UI Features:**
- **Loading states**: Shows spinner while fetching data
- **Error handling**: Displays errors with retry option
- **Pull-to-refresh**: Swipe down to refresh partnerships
- **Empty states**: Helpful messages when no partnerships exist
- **Confirmation dialogs**: For destructive actions like unlinking

### ✅ **Auto-Partnership Creation:**
- Partnerships are automatically created when users play matches together
- Statistics are updated when matches are completed
- No manual setup required - just play matches!

## How It Works

1. **Automatic Partnership Creation:**
   - When a match request is accepted and a `teammate_id` is set
   - The database trigger automatically creates/updates partnership records
   - Statistics are tracked automatically

2. **Partnership Display:**
   - Shows partner name from their profile
   - Displays match statistics (played, won, win %)
   - Separates starred partnerships at the top

3. **User Actions:**
   - Star partnerships to mark as favorites
   - Unlink partnerships to hide them
   - Link new players (placeholder for future email-based linking)

## Future Enhancements

- **Email-based linking**: Add players by email before playing matches
- **Team names**: Custom names for partnerships
- **Performance tracking**: More detailed statistics
- **Partner search**: Find and connect with specific players
