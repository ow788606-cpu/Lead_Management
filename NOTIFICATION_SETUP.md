# Push Notification Setup Guide

## What Was Implemented

Push notifications that alert users 15 minutes before a lead's follow-up time.

## Files Modified/Created

1. **pubspec.yaml** - Added `flutter_local_notifications: ^17.0.0`
2. **android/app/src/main/AndroidManifest.xml** - Added POST_NOTIFICATIONS permission
3. **lib/services/notification_service.dart** - Created notification service
4. **lib/screens/leads/all_leads_screen.dart** - Integrated notification monitoring

## How It Works

1. The app monitors all leads every minute
2. When a lead's follow-up time is within 15 minutes:
   - A push notification appears on the phone's notification panel
   - A snackbar also appears in-app (if app is open)
3. Users can tap the notification to view lead details

## Notification Details

- **Title**: "Lead Follow-up Reminder"
- **Message**: "Follow-up with [Lead Name] in 15 minutes"
- **Trigger**: 15 minutes before follow-up date/time (10:00 AM)
- **Platform**: Android & iOS

## Next Steps to Deploy

1. Run `flutter pub get` to install dependencies
2. For Android:
   - Ensure minSdk is 21 or higher (already configured)
   - Build and test on Android 13+ for full notification support
3. For iOS:
   - Update ios/Podfile if needed
   - Request notification permissions in app

## Testing

To test notifications:
1. Create a lead with follow-up date/time set to 15 minutes from now
2. Keep the app open or in background
3. Wait for the notification to appear

## Notes

- Notifications only trigger for incomplete leads
- Each lead is notified only once per session
- The notification service runs continuously while the app is active
