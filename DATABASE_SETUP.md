# Database Setup Instructions

## To fix the data saving issue, you need to create the required database tables:

### Option 1: Using phpMyAdmin
1. Open phpMyAdmin in your browser (usually http://localhost/phpmyadmin)
2. Select your 'lead' database
3. Go to the SQL tab
4. Copy and paste the contents of `create_tables.sql` file
5. Click "Go" to execute the SQL

### Option 2: Using MySQL Command Line
1. Open command prompt
2. Navigate to MySQL bin directory (usually C:\xampp\mysql\bin)
3. Run: `mysql -u root -p lead < "C:\xampp\htdocs\lead\create_tables.sql"`

### Option 3: Using PHP Script
1. Open command prompt
2. Navigate to your project directory: `cd C:\xampp\htdocs\lead`
3. Run: `C:\xampp\php\php.exe create_lead_tables.php`

## What's Fixed:

1. **Database Storage**: Activities, notes, and tasks now save to database tables
2. **Data Loading**: Data is loaded from database on screen load
3. **Real-time Updates**: Changes are immediately saved to database
4. **Error Handling**: Proper error messages if database operations fail

## Files Created/Updated:

- `api/lead_activities.php` - API for activities
- `api/lead_notes.php` - API for notes  
- `api/lead_tasks.php` - API for tasks
- `lib/services/lead_activity_api.dart` - Updated API service
- `lib/screens/leads/detail_lead_screen.dart` - Updated to use database
- `create_tables.sql` - SQL script to create tables
- `create_lead_tables.php` - PHP script to create tables

After creating the tables, your app will properly save and display activities, notes, and tasks!