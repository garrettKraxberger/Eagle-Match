# Eagle Match - Golf Pairing App

A Flutter mobile application for golfers to find playing partners, create matches, and manage golf partnerships. Built with Supabase backend and designed with USGA-inspired styling.

## Features

### 🏌️ Match Management
- **Create Matches**: Set up golf matches with flexible scheduling and location options
- **Find Partners**: Browse and join available matches from other golfers  
- **Match Requests**: Send and receive requests to join matches
- **Match History**: Track your golf match history and statistics

### 👥 Partnership System (Duos)
- **Automatic Partnerships**: Partners are automatically created when playing matches together
- **Partnership Statistics**: View win rates, matches played, and performance metrics
- **Starred Partners**: Mark favorite playing partners for easy access
- **Partner Management**: Link players by email/phone for account connections

### 🎨 USGA-Inspired Design
- **Professional Styling**: Clean, modern interface matching USGA website aesthetics
- **Brand Colors**: Navy blue primary, gold accents, strategic red highlights
- **Consistent UI**: Card-based layout with professional typography and spacing
- **Responsive Design**: Optimized for mobile golf course usage

### 📱 Core Functionality
- **User Authentication**: Secure login and profile management with Supabase Auth
- **Profile Images**: Support for profile pictures with fallback avatars
- **Real-time Data**: Live updates for matches and requests
- **Location-based**: Course selection with state/county filtering
- **Flexible Scheduling**: Support for specific dates or flexible availability

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **State Management**: StatefulWidget with local state
- **UI Theme**: Custom USGA-inspired theme
- **Authentication**: Supabase Auth
- **Database**: PostgreSQL with Row Level Security (RLS)

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- iOS Simulator / Android Emulator
- Supabase account

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/eagle-match.git
   cd eagle-match
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables**
   Create a `.env` file in the root directory:
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

4. **Set up Supabase database**
   - Run the SQL scripts in order:
   - `setup_database.sql` - Creates main tables and RLS policies
   - `setup_partnerships_table.sql` - Creates partnerships table
   - `add_profile_image_column.sql` - Adds profile image support
   - `migrate_teammate_linking.sql` - Updates teammate references
   - `migrate_profile_images.sql` - Migrates legacy profile images

5. **Run the app**
   ```bash
   flutter run
   ```

## Database Schema

### Core Tables
- **profiles**: User profiles with authentication integration
- **matches**: Golf matches with creator, teammate, and match details
- **match_requests**: Join requests for matches
- **partnerships**: Automatically tracked playing partnerships
- **courses**: Golf course database with location info
- **counties**: Geographic data for location filtering

### Key Features
- **Row Level Security (RLS)**: Secure data access based on user authentication
- **Foreign Key Relationships**: Proper data integrity between tables
- **Automatic Timestamps**: Created/updated tracking for all records
- **Flexible Match Types**: Support for Match Play, Stroke Play, Single, Duo modes

## Documentation

- **[Database Setup Guide](DATABASE_SETUP.md)**: Complete database configuration instructions
- **[USGA UI Implementation](USGA_UI_IMPLEMENTATION.md)**: Design system and UI guidelines
- **[Red Accents Guide](USGA_RED_ACCENTS.md)**: Strategic use of USGA red branding
- **[Partnership System](DUOS_SETUP.md)**: How the duo/partnership system works

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── env/                         # Environment configuration
├── models/                      # Data models
├── screens/                     # UI screens
│   ├── auth/                    # Authentication screens
│   ├── navigation/              # Navigation and tab screens
│   ├── profile/                 # Profile management
│   └── tabs/                    # Main app tab screens
├── services/                    # API and business logic
├── theme/                       # USGA theme implementation
├── utils/                       # Utility functions
└── widgets/                     # Reusable UI components
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

For questions or support, please open an issue on GitHub.

---

Built with ❤️ for the golf community
