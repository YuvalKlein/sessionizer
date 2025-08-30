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

### Testing

- **Unit Tests**: Comprehensive unit tests have been written for all core services (`AuthService`, `UserService`, `SessionService`, `PostService`).
- **Widget Tests**: Widget tests have been written for the `PostListScreen` and `CreatePostScreen` to ensure that the UI behaves as expected.
- **Mocking**: The `mockito` package is used to mock dependencies, ensuring that tests are isolated and repeatable.
- **Build Runner**: The `build_runner` package is used to generate mock classes.

## Next Steps

- **Profile Screen**: Create a user profile screen where users can view their own posts and edit their profile information.
- **Comments**: Add a feature that allows users to comment on posts.
- **Likes**: Add a feature that allows users to "like" posts.
