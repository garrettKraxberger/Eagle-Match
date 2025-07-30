# Database Setup for Eagle Match

## Supabase Database Schema

To make the `find_screen.dart` and `matches_screen.dart` functional, you need to create the following tables in your Supabase database.

### Quick Setup

1. Go to your Supabase project dashboard
2. Navigate to the SQL Editor
3. Copy and paste the SQL from `lib/models/database_schema.sql`
4. Run the SQL to create all necessary tables and policies

### Tables Created

1. **profiles** - User profile information
2. **counties** - Available counties for location selection
3. **courses** - Golf courses
4. **matches** - Match postings created by users
5. **match_requests** - Join/invite requests for matches
6. **notifications** - User notifications

### Sample Data (Optional)

You can add some sample counties and courses to test the functionality:

```sql
-- Sample counties
INSERT INTO counties (county, state) VALUES
('Orange County', 'CA'),
('Los Angeles County', 'CA'),
('San Diego County', 'CA'),
('Maricopa County', 'AZ'),
('Cook County', 'IL');

-- Sample courses
INSERT INTO courses (name, city, state) VALUES
('Pebble Beach Golf Links', 'Pebble Beach', 'CA'),
('TPC Scottsdale', 'Scottsdale', 'AZ'),
('Augusta National', 'Augusta', 'GA'),
('Bethpage Black', 'Farmingdale', 'NY'),
('Torrey Pines', 'La Jolla', 'CA');
```

### Features Now Available

After setting up the database, your app will have:

#### Find Screen (`find_screen.dart`)
- ✅ Load real matches from database
- ✅ Display match details (location, schedule, type, etc.)
- ✅ Join match functionality 
- ✅ Request invite functionality
- ✅ Pull-to-refresh
- ✅ Loading states and error handling

#### Matches Screen (`matches_screen.dart`)
- ✅ Load real match requests from database
- ✅ Accept/decline match requests
- ✅ View confirmed matches
- ✅ Notifications system
- ✅ Pull-to-refresh
- ✅ Loading states

### Data Flow

1. Users create matches in `create_screen.dart` → saved to `matches` table
2. Other users see these matches in `find_screen.dart`
3. Users can join/request invites → creates entries in `match_requests` table
4. Match creators see requests in `matches_screen.dart`
5. When requests are accepted → users are added to match participants

### Authentication Required

Both screens now require user authentication to function properly. Make sure users are signed in before accessing these screens.
