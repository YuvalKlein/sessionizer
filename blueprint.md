
# Project Blueprint

## Overview

This is a Flutter application that allows users to book sessions with instructors. The application features a robust, Calendly-like scheduling system that allows instructors to define their availability with a high degree of control, which clients can then use to book available session slots.

## Application Architecture

### Services

- **`AuthService`**: Manages user authentication (login, registration, logout).
- **`UserService`**: Manages user data and roles (e.g., `isInstructor`).
- **`SessionTemplateService`**: Handles fetching `SessionTemplate` data from Firestore for a specific instructor.
- **`AvailabilityService`**: Manages all CRUD (Create, Read, Update, Delete) operations for instructor `Availability` rules in Firestore.

### UI Screens & Widgets

- **`LoginScreen` / `RegistrationScreen`**: Standard user authentication screens.
- **`MainScreen`**: The primary screen after login, containing the main `BottomNavigationBar`.
- **`SessionsScreen`**: The main view for clients to see and book available sessions.
- **`SetScreen`**: A screen for instructors to manage their settings, including their session templates.
- **`ScheduleScreen`**: A dedicated screen for instructors to manage their availability. It features a tabbed interface to separate "Weekly Recurring" schedules from "Date Overrides."
- **`ProfileScreen`**: Displays the user's profile information.
- **`AvailabilityForm`**: A comprehensive modal bottom sheet form used to create and edit availability rules. The form is dynamic and adapts its fields based on whether the rule is for a recurring week day or a specific date.

---

## Implemented Features

- **User Authentication**: Secure login, registration, and session management.
- **Role Management**: The app distinguishes between regular users and instructors, showing instructor-specific UI elements and functionality only to authenticated instructors.
- **Session Template Management**: Instructors can define the types of sessions they offer (e.g., "1-hour Personal Training," "30-minute Consultation").
- **Advanced Instructor Scheduling**:
  - **Weekly Recurring Availability**: Instructors can set their standard weekly hours for each day of the week.
  - **Specific Date Overrides**: Instructors can override their weekly schedule for a particular date, either to add one-off availability or to block out time.
  - **Granular Control**: For each availability rule, instructors can specify:
    - The time range (`startTime`, `endTime`).
    - Allowed session types for that slot.
    - Break times between sessions.
    - Booking lead time and how far in the future clients can book.

---

## Data Models

### `SessionTemplate`

Represents a type of session that an instructor can offer.

- `id`: `String` - The unique document ID.
- `title`: `String` - The name of the session (e.g., "Yoga Basics").
- `timeZoneOffsetInHours`: `num` - The instructor's timezone offset.
- `notifyCancelation`: `bool` - Flag to notify on cancellation.
- `createdTime`: `int` - Timestamp of creation.
- `duration`: `int` - Session duration.
- `durationUnit`: `String` - The unit for duration (e.g., "minutes").
- `details`: `String` - A detailed description of the session.
- `idCreatedBy`: `String` - The user ID of the creator.
- `idInstructor`: `String` - The user ID of the instructor.
- `playersIds`: `List<String>` - List of participant IDs.
- `maxPlayers`: `int` - Maximum number of participants.
- `minPlayers`: `int` - Minimum number of participants.
- `canceled`: `bool` - Flag if the session is canceled.
- `repeatingSession`: `bool` - Flag for repeating sessions.
- `attendanceData`: `List<dynamic>` - Data on attendance.
- `showParticipants`: `bool` - Flag to show participants publicly.
- `category`: `String` - The category of the session.

### `Availability`

Represents a rule that defines when an instructor is available for bookings.

- `id`: `String` - The unique document ID.
- `instructorId`: `String` - The ID of the instructor this rule belongs to.
- `type`: `String` - The type of rule. Can be **`'weekly'`** or **`'date'`**.
- `dayOfWeek`: `int?` - The day of the week (1-7 for Monday-Sunday). **Required if `type` is `'weekly'`**.
- `date`: `DateTime?` - The specific date for an override. **Required if `type` is `'date'`**.
- `startTime`: `String` - The start time of the slot in "HH:mm" format.
- `endTime`: `String` - The end time of the slot in "HH:mm" format.
- `allowedSessionTemplates`: `List<String>` - A list of `SessionTemplate` IDs that can be booked in this slot.
- `breakTime`: `int` - Break time in minutes between sessions.
- `customDuration`: `int?` - An optional duration in minutes to override the session template's default.
- `daysInFuture`: `int` - How many days ahead clients can book.
- `bookingLeadTime`: `int` - The minimum notice (in minutes) required for a booking.
