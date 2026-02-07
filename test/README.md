# Smart Schools System Uganda (SSU)

## Project Overview

The Smart Schools System Uganda (SSU) is a comprehensive, feature-rich school management system designed to streamline academic, administrative, and financial operations for educational institutions in Uganda. It supports multiple user roles, including Chief Admin, Head Teacher, Teacher, Student, Parent, and System Admin, and leverages Artificial Intelligence to enhance various functionalities.

## Key Features

### User & Authentication Management
- Secure login, registration, and Google Sign-In.
- Biometric authentication for quick access.
- Detailed user profiles with role-based access control.

### School Administration
- Comprehensive school setup and configuration.
- Management of class levels and streams (e.g., Senior 1 A, Senior 1 B).

### Academic Management
- **Subjects:** Pre-defined O-Level and A-Level subjects with detailed paper structures.
- **Lesson Plans & Schemes of Work:** Tools for creating, editing, and AI-powered generation of lesson plans and schemes of work.
- **Exams & Questions:** Management of exam questions, creation of question banks, and professional PDF typesetting for exams.
- **Grading & Marks:** Advanced grading models for O-Level and A-Level, with dedicated screens for efficient marks entry.
- **Report Cards:** Generation of individual and batch report cards, featuring AI-generated comments from class and head teachers.
- **Timetable Management:** AI-powered timetable generation, management of subject constraints, and personalized timetable views for classes and teachers.
- **Performance Analysis:** Tools to analyze class and student performance, identifying top performers and students needing support.

### Financial Management
- Management of fee structures.
- Recording of fee payments and tracking of student fee balances.
- Comprehensive salary management for all staff members, including bulk payment processing and salary history reports.

### Student & Parent Management
- Streamlined enrollment processes for new students and parents.
- Tracking of student applications with approval/rejection workflows.
- Detailed student information views.

### AI Integration
- **Voice-Controlled AI Assistant:** For intuitive navigation and data entry (e.g., recording marks).
- **AI Content Studio:** A general-purpose AI assistant for various tasks.
- **Social Media Suggestions:** AI-powered suggestions for engaging social media posts.
- **Advanced AI Services:** Integration with ElevenLabs for voice cloning, Stability AI for image generation, and orchestration for video generation from lesson plans.

### Communication & Engagement
- Real-time audio chat functionality.
- Social media post scheduling for school announcements and events.

## Architectural Highlights

The project follows a modular architecture, organizing code into distinct layers:
- **`lib/models`**: Defines data structures and business entities.
- **`lib/providers`**: Manages application state and data flow.
- **`lib/screens`**: Contains the user interface for different application views.
- **`lib/services`**: Encapsulates business logic, API interactions, and external service integrations.
- **`lib/widgets`**: Houses reusable UI components.

Communication with the backend is handled through a centralized `ApiClient`, ensuring authenticated and structured data exchange. The application leverages Firebase for certain functionalities (e.g., Cloud Functions, Firestore for some data streams) and integrates various third-party AI APIs.

## Getting Started

(Instructions on how to set up and run the project will be provided here.)

## Contributing

(Guidelines for contributing to the project will be provided here.)