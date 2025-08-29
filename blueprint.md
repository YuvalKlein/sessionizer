# Project Blueprint

## Overview

This is a Flutter application with a basic authentication flow using Firebase Authentication. The application allows users to register and log in with their email and password. It also includes a theme toggle for light, dark, and system theme modes.

## Implemented Features

*   **Authentication:**
    *   User registration with email and password.
    *   User login with email and password.
    *   Basic error handling for registration and login.
*   **Routing:**
    *   Navigation between home, login, and registration screens using `go_router`.
*   **Theming:**
    *   Light, dark, and system theme modes.
    *   Custom theme with `google_fonts`.
    *   Theme toggle functionality using `provider`.
*   **UI:**
    *   Separate screens for home, login, and registration.
    *   Forms for user input with validation.
    *   Bottom navigation bar with three tabs: "Sessions", "Set", and "Schedule".

## Current Plan: "Set" Screen

The "Set" screen will be the central hub for administrators to configure the core business rules of the application. This includes defining what types of sessions can be booked, when the business is open, and where the sessions take place.

### Design & Features:

*   **Tabbed Layout:** The screen will be organized into three distinct tabs for a clean user experience: "Templates," "Hours," and "Locations."
*   **Session Templates:**
    *   A form with fields for:
        *   Session Name (Text)
        *   Minimum Players (Number)
        *   Maximum Players (Number)
        *   Price (Number)
    *   A "Save Template" button will write this data as a new document to the `templates` collection in Firestore.
*   **Working Hours:**
    *   A list of all seven days of the week.
    *   Each day will feature two interactive time pickers: one for the "Start Time" and one for the "End Time."
    *   A "Save Hours" button will save the entire weekly schedule to the `times` collection in Firestore.
*   **Locations:**
    *   A form with a field for:
        *   Location Name (Text)
    *   A "Save Location" button will write this data as a new document to the `locations` collection in Firestore.

### Implementation Steps:

1.  Add the `cloud_firestore` dependency to `pubspec.yaml`.
2.  Restructure the `set_screen.dart` file to use a `DefaultTabController` and `TabBar` to create the three sections.
3.  Create the UI for the "Session Templates" tab, including all necessary input fields and the save button.
4.  Implement the Firestore logic to save a new session template.
5.  Create the UI for the "Working Hours" tab.
6.  Implement the Firestore logic to save the working hours.
7.  Create the UI for the "Locations" tab.
8.  Implement the Firestore logic to save a new location.
