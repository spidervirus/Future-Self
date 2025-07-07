# Frontend Development Roadmap

This document outlines the development plan for the Future Self Flutter application, covering UI/UX, state management, feature implementation, and testing.

## Phase 1: Foundation & Onboarding (Completed)

### 1.1. Project Setup
- **Task:** Initialize Flutter project with a clean architecture.
- **Details:** Set up directory structure, dependency management (GetIt, Dio, etc.), and define core architectural patterns (e.g., BLoC, Provider).
- **Status:** ✅ Done

### 1.2. UI Kit & Design System
- **Task:** Develop a comprehensive UI kit based on the app's design language.
- **Details:** Create reusable widgets for buttons, text fields, cards, dialogs, and navigation components. Define theme data (colors, typography, spacing). The "Cosmic Dream" theme has been implemented.
- **Status:** ✅ Done

### 1.3. Onboarding Screens
- **Task:** Implement the multi-step onboarding process.
- **Details:** Build the UI for all onboarding questions, including text inputs, calendars, dropdowns, and file uploads. A data-driven `PageView` has been implemented.
- **Status:** ✅ Done

### 1.4. State Management for Onboarding
- **Task:** Implement state management for the onboarding flow.
- **Details:** Use a state management solution (Flutter BLoC) to handle user input, validation, and data persistence during the onboarding process.
- **Status:** ✅ Done

### 1.5. Navigation
- **Task:** Implement routing for the application.
- **Details:** `go_router` has been set up to handle navigation between the onboarding flow and the main app.
- **Status:** ✅ Done

## Phase 2: Core Experience - The Dashboard (Completed)

### 2.1. Dashboard Scaffolding
- **Task:** Design and build the main user dashboard and all associated placeholder screens.
- **Details:** The main dashboard layout has been built. The `DailyMessageCard` has been extracted into its own widget. A "Quick Actions" grid provides navigation to all core features. All placeholder screens (Chat, Journal, Vision Board, Affirmations, Activities) have been created and are fully navigable from the dashboard.
- **Status:** ✅ Done

## Phase 3: Core Features (Upcoming)

### 3.1. API Integration for User Registration
- **Task:** Connect the onboarding flow to the backend.
- **Details:** Implement API calls to register the user and submit their onboarding data to the backend.
- **Status:** To Do

### 3.2. Chat Interface
- **Task:** Develop the real-time chat UI.
- **Details:** Build a chat screen with support for text messages, timestamps, and user avatars. Implement WebSocket integration for real-time communication.
- **Status:** To Do

### 3.3. Voice Messaging
- **Task:** Implement voice message recording and playback.
- **Details:** Integrate a voice recording plugin to capture user audio. Develop UI components for recording, sending, and playing voice notes.
- **Status:** To Do

### 3.4. Vision & Belief Boards
- **Task:** Implement the vision and belief board features.
- **Details:** Allow users to upload images and create text-based belief statements. Develop a visually appealing grid-based layout for the boards.
- **Status:** To Do

## Phase 4: Wellness & Engagement (Upcoming)

### 4.1. Journaling
- **Task:** Develop the electronic journal feature.
- **Details:** Create a rich-text editor for journal entries, with options for formatting and adding media. Implement local storage for offline access.
- **Status:** To Do

### 4.2. Affirmations
- **Task:** Implement the voice affirmation feature.
- **Details:** Allow users to record and listen to personalized affirmations. Integrate with backend to fetch AI-generated affirmations.
- **Status:** To Do

### 4.3. Daily Activity System
- **Task:** Build the UI for the mood-based activity suggestions.
- **Details:** Create a user-friendly interface for selecting moods and displaying recommended activities.
- **Status:** To Do

### 4.4. Push Notifications
- **Task:** Integrate a push notification system.
- **Details:** Set up Firebase Cloud Messaging (FCM) or a similar service to handle daily messages, reminders, and alerts.
- **Status:** To Do

## Phase 5: Refinement & Deployment (Upcoming)

### 5.1. Cross-Platform Optimization
- **Task:** Ensure a consistent and high-quality experience on all platforms.
- **Details:** Test and optimize the UI/UX for iOS, Android, and Web. Address any platform-specific issues.
- **Status:** To Do

### 5.2. Testing & Quality Assurance
- **Task:** Conduct thorough testing of the application.
- **Details:** Write unit, widget, and integration tests. Perform manual testing to identify and fix bugs.
- **Status:** To Do

### 5.3. App Store Deployment
- **Task:** Prepare and submit the app to the Apple App Store and Google Play Store.
- **Details:** Create app store listings, generate screenshots, and follow the submission guidelines for each platform.
- **Status:** To Do

### 5.4. Web Deployment
- **Task:** Deploy the Flutter web application.
- **Details:** Configure the web build and host it on a suitable platform (e.g., Firebase Hosting, Netlify).
- **Status:** To Do 