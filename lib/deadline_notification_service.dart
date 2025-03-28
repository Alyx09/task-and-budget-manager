import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:flutter/material.dart';

class DeadlineNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  // Initialize notification settings
  static Future<void> initialize() async {
    try {
      // Initialize timezone data
      tz_init.initializeTimeZones();
      
      // Set local timezone - replace with your timezone or get it dynamically
      tz.setLocalLocation(tz.getLocation('Asia/Manila'));
      
      // Set up Android settings
      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Initialize notification settings (Android only version)
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );
      
      // Initialize notifications with settings
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      // Create notification channels right after initialization
      await _createNotificationChannels();
      
      print('Notification service initialized successfully');
    } catch (e) {
      print('Failed to initialize notification service: $e');
    }
  }
  
  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // You can add navigation or other actions when notification is tapped
    print('Notification tapped: ${response.payload}');
    
    // Add your navigation logic here. Example:
    // if (response.payload?.startsWith('deadline_') ?? false) {
    //   final id = int.tryParse(response.payload!.split('_')[1]) ?? 0;
    //   // Navigate to task details page or relevant screen
    // }
  }
  
  // Check and request permissions
  static Future<bool> requestPermissions() async {
    try {
      // Explicitly cast to the appropriate type
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
          
      if (androidPlugin != null) {
        final bool? permissionGranted = await androidPlugin.requestPermission();
        print('Notification permission granted: $permissionGranted');
        return permissionGranted ?? false;
      }
      
      // Since you're targeting Android only, we'll skip iOS permission handling
      
      print('Platform plugin is null, assuming permissions granted');
      return true;
    } catch (e) {
      print('Error requesting notification permission: $e');
      return false;
    }
  }
  
  // Create notification channels (required for Android 8.0+)
  static Future<void> _createNotificationChannels() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
          
      if (androidPlugin != null) {
        // Create deadline reminder channel
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'deadline_reminder_channel',
            'Deadline Reminders',
            description: 'Notifications for upcoming deadlines',
            importance: Importance.high,
            enableVibration: true,
          ),
        );
        
        // Create test notification channel
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'test_channel',
            'Test Notifications',
            description: 'Testing notifications',
            importance: Importance.max,
            enableLights: true,
            enableVibration: true,
          ),
        );
        
        print('Notification channels created successfully');
      }
    } catch (e) {
      print('Failed to create notification channels: $e');
    }
  }
  
  // Show a test notification immediately (useful for debugging)
  static Future<void> showTestNotification() async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'Testing notifications',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'Test notification ticker',
        enableLights: true,
        color: Color.fromARGB(255, 255, 0, 0),
        ledColor: Color.fromARGB(255, 255, 0, 0),
        ledOnMs: 1000,
        ledOffMs: 500,
      );
      
      const notificationDetails = NotificationDetails(
        android: androidDetails,
      );
      
      await _notifications.show(
        999,
        'Test Notification',
        'This is a test notification',
        notificationDetails,
      );
      print('Test notification sent successfully');
    } catch (e) {
      print('Test notification failed: $e');
    }
  }
  
  // Schedule a deadline notification
  static Future<void> scheduleDeadlineReminder({
    required int id,
    required String title,
    required String body,
    required DateTime deadline,
    List<DateTime>? reminderTimes,
  }) async {
    try {
      // Ensure permissions are granted first
      final hasPermission = await requestPermissions();
      
      if (!hasPermission) {
        print('Notification permissions not granted');
        return;
      }
      
      // Default reminder: 1 day before, 1 hour before
      reminderTimes ??= [
        deadline.subtract(const Duration(days: 1)),
        deadline.subtract(const Duration(hours: 1)),
      ];
      
      print('Scheduling ${reminderTimes.length} reminders for deadline: $deadline');
      
      // Schedule reminder notifications
      int scheduledCount = 0;
      final now = DateTime.now().subtract(const Duration(seconds: 5)); // Small buffer
      
      for (int i = 0; i < reminderTimes.length; i++) {
        final DateTime reminderTime = reminderTimes[i];
        
        // Only schedule if the time is in the future
        if (reminderTime.isAfter(now)) {
          await _scheduleNotification(
            id: id + i, // Use different IDs for each reminder
            title: title,
            body: '$body - ${_formatTimeRemaining(deadline, reminderTime)}',
            scheduledTime: reminderTime,
            payload: 'deadline_$id',
          );
          scheduledCount++;
        } else {
          print('Skipping reminder at $reminderTime as it is in the past');
        }
      }
      
      print('Successfully scheduled $scheduledCount notifications');
      
      // For debugging: list all pending notifications
      final pendingNotifications = await getPendingNotifications();
      for (final notification in pendingNotifications) {
        print('Pending notification: ID=${notification.id}, Title=${notification.title}');
      }
    } catch (e) {
      print('Failed to schedule deadline reminder: $e');
    }
  }
  
  // Helper to schedule a single notification
  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      final androidDetails = const AndroidNotificationDetails(
        'deadline_reminder_channel',
        'Deadline Reminders',
        channelDescription: 'Notifications for upcoming deadlines',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        fullScreenIntent: true, // This helps with display on some devices
        category: AndroidNotificationCategory.reminder,
      );
      
      final notificationDetails = NotificationDetails(
        android: androidDetails,
      );
      
      // Convert local DateTime to TZDateTime
      final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
      
      print('Scheduling notification for: ${tzScheduledTime.toString()}');
      
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        notificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: 
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
        matchDateTimeComponents: DateTimeComponents.time, // This helps with exact timing
      );
      
      print('Successfully scheduled notification with ID: $id for ${tzScheduledTime.toString()}');
    } catch (e) {
      print('Failed to schedule notification: $e');
      print('Error details: $e');
    }
  }
  
  // Format the time remaining message
  static String _formatTimeRemaining(DateTime deadline, DateTime reminderTime) {
    final Duration remaining = deadline.difference(reminderTime);
    
    if (remaining.inDays > 0) {
      return '${remaining.inDays} day(s) remaining';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours} hour(s) remaining';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes} minute(s) remaining';
    } else {
      return 'Due now!';
    }
  }
  
  // Schedule an exact notification for testing (use for debug)
  static Future<void> scheduleExactTestNotification(int secondsFromNow) async {
    try {
      final scheduledTime = DateTime.now().add(Duration(seconds: secondsFromNow));
      
      await _scheduleNotification(
        id: 1000,
        title: 'Exact Test Notification',
        body: 'This notification should appear in exactly $secondsFromNow seconds',
        scheduledTime: scheduledTime,
        payload: 'exact_test',
      );
      
      print('Scheduled exact test notification for $scheduledTime');
    } catch (e) {
      print('Failed to schedule exact test notification: $e');
    }
  }
  
  // Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      print('Cancelled notification with ID: $id');
    } catch (e) {
      print('Failed to cancel notification: $e');
    }
  }
  
  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print('Cancelled all notifications');
    } catch (e) {
      print('Failed to cancel all notifications: $e');
    }
  }
  
  // Get pending notification requests (useful for debugging)
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final List<PendingNotificationRequest> pendingNotifications = 
          await _notifications.pendingNotificationRequests();
      print('Pending notifications: ${pendingNotifications.length}');
      return pendingNotifications;
    } catch (e) {
      print('Failed to get pending notifications: $e');
      return [];
    }
  }
  
  // Check if notifications are enabled (Android only)
  static Future<bool> areNotificationsEnabled() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
          
      if (androidPlugin != null) {
        final bool? enabled = await androidPlugin.areNotificationsEnabled();
        return enabled ?? false;
      }
      
      return true;
    } catch (e) {
      print('Error checking if notifications are enabled: $e');
      return false;
    }
  }
}