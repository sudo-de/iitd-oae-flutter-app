# IIT Delhi OAE - Notification System Setup

## Overview
The app now supports both local notifications and Firebase Cloud Messaging (FCM) for push notifications. The notification system is automatically initialized when the app starts and handles user role-based subscriptions.

## Features

### 1. Local Notifications
- Test notifications from the driver dashboard settings
- In-app notifications for user actions
- Custom notification sounds and icons

### 2. Firebase Cloud Messaging (FCM)
- Push notifications from server
- Role-based topic subscriptions
- Background message handling
- Token management

## User Role Subscriptions

### Drivers
- Topic: `drivers` (all drivers)
- Topic: `driver_{userId}` (specific driver)

### Students
- Topic: `students` (all students)
- Topic: `student_{userId}` (specific student)

### Admins
- Topic: `admins` (all admins)
- Topic: `system_notifications` (system-wide notifications)

## Testing Notifications

### 1. Local Test Notification
1. Open the Driver Dashboard
2. Tap "System Settings"
3. Enable "Push Notifications" if not already enabled
4. Tap "Test Notification"
5. Check your device's notification panel

### 2. FCM Token Verification
1. Open the Driver Dashboard
2. Tap "System Settings"
3. Scroll down to "Support & Help" section
4. Tap "FCM Token" to see the current token
5. The token should be displayed in the snackbar

### 3. Server-Side Testing
To test push notifications from a server, you can use Firebase Console or send a POST request to FCM:

```bash
curl -X POST -H "Authorization: key=YOUR_SERVER_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "to": "TOPIC_NAME",
       "notification": {
         "title": "IIT Delhi OAE",
         "body": "Test push notification"
       },
       "data": {
         "click_action": "FLUTTER_NOTIFICATION_CLICK",
         "type": "test"
       }
     }' \
     https://fcm.googleapis.com/fcm/send
```

## Configuration Files

### Android
- `android/app/src/main/AndroidManifest.xml` - Permissions and FCM service
- `android/app/src/main/res/drawable/ic_notification.xml` - Notification icon
- `android/app/src/main/res/values/colors.xml` - Notification color

### iOS
- `ios/Runner/Info.plist` - Background modes and permissions

## Troubleshooting

### Common Issues

1. **Notifications not showing**
   - Check if notifications are enabled in device settings
   - Verify FCM token is generated (check in settings)
   - Ensure Firebase project is properly configured

2. **FCM Token not available**
   - Check internet connection
   - Verify Firebase configuration
   - Check Firebase Console for any issues

3. **Background notifications not working**
   - Ensure background modes are enabled in iOS
   - Check Android manifest for proper service configuration

### Debug Information
- FCM Token is displayed in the settings
- Debug logs are printed when `kDebugMode` is true
- Check console for any error messages

## Next Steps

1. **Server Integration**: Set up a server to send push notifications
2. **Notification Categories**: Add different notification types (ride requests, earnings, etc.)
3. **Rich Notifications**: Add images and actions to notifications
4. **Analytics**: Track notification engagement

## Files Modified

- `pubspec.yaml` - Added firebase_messaging dependency
- `lib/services/notification_service.dart` - New notification service
- `lib/main.dart` - Initialize notification service
- `lib/providers/auth_provider.dart` - Handle user subscriptions
- `lib/screens/driver_dashboard.dart` - Updated notification handling
- `android/app/src/main/AndroidManifest.xml` - Added FCM permissions
- `ios/Runner/Info.plist` - Added background modes 