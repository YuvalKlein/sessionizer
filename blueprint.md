# Project Blueprint

## Overview

This document outlines the architecture, features, and implementation details of the Flutter application. It serves as a living document, updated with each new feature or significant change.

## Implemented Features

### Core Services

- **Authentication Service (`AuthService`)**: Handles user authentication, including sign-in with Google and registration with email and password. It also manages user data in the Firestore `users` collection.
- **User Service (`UserService`)**: Provides a stream to listen for real-time updates to a user's document in Firestore.
- **Session Service (`SessionService`)**: Manages fitness class sessions. It allows users to view upcoming sessions, and join or leave a session. It interacts with the `sessions` collection in Firestore.
- **Post Service (`PostService`)**: Manages user posts, including creating, reading, and deleting posts from the Firestore `posts` collection.

### Post Feature

- **Post List Screen (`PostListScreen`)**: Displays a list of all posts in chronological order. Each post is displayed in a `Card` and shows the post content, the author's email, and a formatted timestamp. Users can delete their own posts.
- **Create Post Screen (`CreatePostScreen`)**: Allows users to create new posts. It includes a `TextFormField` with a character counter and a character limit of 280 characters. The "Post" button is full-width for better usability.

### Profile Screen Feature

- **Profile Screen (`ProfileScreen`)**: Displays the logged-in user's profile information, including their display name, email, and profile picture. It also includes a toggle switch that allows the user to enable or disable "Instructor Mode," which updates their `isInstructor` status in Firestore.

### Testing

- **Unit Tests**: Comprehensive unit tests have been written for all core services (`AuthService`, `UserService`, `SessionService`, `PostService`).
- **Widget Tests**: Widget tests have been written for the `PostListScreen`, `CreatePostScreen`, and `ProfileScreen` to ensure that the UI behaves as expected.
- **Mocking**: The `mockito` and `fake_cloud_firestore` packages are used to mock dependencies, ensuring that tests are isolated and repeatable.
- **Build Runner**: The `build_runner` package is used to generate mock classes.
- **Test Data Generation**: The `faker` package is used to generate realistic mock data for tests.

## Next Steps

- **Comments**: Add a feature that allows users to comment on posts.
- **Likes**: Add a feature that allows users to "like" posts.
