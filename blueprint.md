# Project Blueprint

## Overview

This document outlines the structure and features of the Flutter scheduling application. The app allows for two types of users: instructors and clients. Instructors can manage their schedules and availability, while clients can book appointments with instructors.

## Features

- **User Authentication:** Users can register and log in using email and password.
- **Role-Based Access:** The app distinguishes between instructors and clients, showing different dashboards and functionalities for each.
- **Instructor Features:**
  - Create, view, edit, and delete schedules.
  - Set a default schedule.
  - Manage availability for each day of the week.
  - Override availability for specific dates.
- **Client Features:**
  - View available instructors.
  - Book appointments with instructors based on their availability.
- **Navigation:** The app uses `go_router` for declarative navigation, handling redirects based on authentication state and user role.

## Style and Design

- **Theme:** The app uses Material 3 design principles with a custom color scheme and typography.
- **Layout:** The layout is designed to be responsive and work on both mobile and web.
- **Components:** The app uses a variety of Material components, including `Scaffold`, `AppBar`, `ElevatedButton`, `TextFormField`, `StreamBuilder`, and `FutureBuilder`.

## Current Plan

- Implement the remaining UI screens.
- Fix any existing bugs or errors.
- Refactor the code to improve readability and maintainability.
