# IIT Delhi OAE Flutter App

A comprehensive Flutter application for the Office of Academic Engagement (OAE) at IIT Delhi, providing transportation and academic management features for students, drivers, and administrators.

## Features

### Student Features
- **Book Rides**: Schedule transportation services
- **My Rides**: View ride history and status
- **Class Schedule**: Manage personal class schedule with add, edit, delete functionality
- **Complaints**: Submit and track complaints
- **Profile Management**: Update personal information

### Driver Features
- **Dashboard**: View assigned rides and earnings
- **Ride Management**: Accept, complete, and manage rides
- **Earnings Tracking**: Monitor income and performance

### Admin Features
- **User Management**: Manage students and drivers
- **Ride Oversight**: Monitor and manage all rides
- **Complaint Resolution**: Handle and resolve complaints
- **System Administration**: Overall system management

## Class Schedule Feature

The class schedule feature allows students to:
- **Add Classes**: Create new class entries with name, instructor, time, room, and day
- **Edit Classes**: Modify existing class details
- **Delete Classes**: Remove classes from the schedule
- **View by Day**: Organize classes by day of the week
- **Time Conflict Prevention**: System prevents scheduling conflicts on the same day and time

### Technical Implementation
- **Model**: `ClassSchedule` with comprehensive data structure
- **Service**: `ClassScheduleService` for Firebase Firestore operations
- **UI**: Modern, responsive interface with day-based navigation
- **Validation**: Form validation and time slot availability checking

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
