# Project Blueprint: AI-Enhanced Flutter App

## Overview

This document outlines the features, design, and architecture of a Flutter application built with AI assistance. The goal is to create a robust, well-structured, and visually appealing application that serves as a template for modern Flutter development.

## Implemented Features & Design

... (previous features remain here) ...

### User Profile Screen & Instructor Toggle
- **Dedicated Profile Page:** A new `ProfileScreen` (`lib/ui/profile_screen.dart`) has been added to the application.
- **Navigation Integration:** The profile page is accessible via a new, always-visible "Profile" tab in the main bottom navigation bar.
- **Real-time Data Display:** The screen uses a `StreamBuilder` to listen for live updates to the user's document in Firestore, displaying their name, email, and profile picture.
- **Instructor Mode Toggle:**
    - A `SwitchListTile` on the profile screen allows users to enable or disable "Instructor Mode."
    - Toggling the switch directly updates the `isInstructor` boolean field in their corresponding Firestore user document in real-time.
- **Role-Based Navigation:** The main navigation bar (`lib/ui/main_screen.dart`) is now fully dynamic. The "Set" and "Schedule" tabs will automatically appear or disappear based on the `isInstructor` status, providing a seamless, role-based user experience.


## Current Plan: Build a User Profile Screen

This section details the plan for the current requested change.

### Goal
To replace the placeholder `HomeScreen` with a functional and visually appealing user profile page that displays after a successful login.

### Action Steps
1.  **Fetch User Data:** The screen will asynchronously fetch the currently logged-in user's data (display name, email, and photo URL) from the `users` collection in Firestore.
2.  **Display User Information:**
    - A `FutureBuilder` will be used to handle the loading state while data is being fetched.
    - The user's profile picture will be displayed in a circular avatar. A placeholder icon will be used if no photo URL exists.
    - The user's display name and email will be shown in a clean, readable format.
3.  **Implement Sign-Out:**
    - A prominent "Sign Out" button will be included on the screen.
    - Pressing the button will trigger the `AuthService.signOut()` method.
    - After signing out, the user will be automatically navigated back to the main login screen (`/`) using `go_router`.
4.  **UI/UX Polish:** The layout will be centered and styled for a modern, clean aesthetic, consistent with the rest of the application's theme.
