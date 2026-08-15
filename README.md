# Face-based Mid-day Meal System 2.0 🍱

A modern, highly efficient mobile application built with Flutter to streamline and digitize the Mid-day Meal distribution process in schools using facial recognition and AI-powered food nutrition analysis.

## ✨ Features

*   **👤 Face-based Verification:** Fast and secure student identification using facial recognition to eliminate proxy attendance and ensure meals reach the right students.
*   **🍛 AI Food Quality & Nutrition Analysis:** Automatically analyze a photo of the served meal to estimate nutritional value (carbohydrates, proteins, calories, vitamins, and fat). It uses a smart local estimator with optional Gemini API integration.
*   **📋 Student Registration:** Easy onboarding flow to register new students with their details, allergies, and initial face encoding.
*   **📊 Automated Meal Logging:** Digital ledger of every meal served, preventing double-serving and maintaining accurate, transparent records.
*   **📅 Monthly Reports:** Comprehensive analytics and reporting screens to track meal distribution trends and nutrition averages over time.
*   **🔐 Secure & Privacy-focused:** Sensitive biometric encodings and keys are kept out of version control and managed securely on the backend.

## 🛠️ Technology Stack

*   **Frontend:** Flutter (Dart)
*   **Backend Support:** Python, FastAPI, SQLite (Requires the companion backend server)
*   **Authentication & State:** Shared Preferences, Secure API calls (Bearer tokens)
*   **AI/ML:** Gemini 2.0 Flash (optional) & Local heuristic image processing

## 🚀 Getting Started

### Prerequisites
*   Flutter SDK installed
*   The **companion backend server** running locally or deployed.

### Setup
1.  Clone the repository.
2.  Run `flutter pub get` to install dependencies.
3.  Start the app on an emulator or physical device using `flutter run`.
4.  Open the **Settings** (⚙️) inside the app to configure your backend server IP address and optional Gemini API key.

## 🔒 Security Note
This repository strictly ignores sensitive files (`.env`, keystores, api keys). Ensure you configure your environment variables safely when deploying the application.
