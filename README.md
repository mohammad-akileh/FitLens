# 📸 FitLens - AI-Powered Calorie Tracker

![FitLens Banner](https://via.placeholder.com/1200x400?text=FitLens+AI+Calorie+Tracker)
[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20Cloud%20Functions-orange?logo=firebase)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Language-Dart-blue?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

## 🎓 Graduation Project
**FitLens** is an intelligent mobile application designed to simplify nutritional tracking using Artificial Intelligence. By leveraging computer vision and cloud computing, it allows users to scan meals, estimate calories instantly, and receive personalized health recommendations.

> **Download the latest APK:** [FitLens v1.0.0 Release](https://github.com/mohammad-akileh/FitLens/releases/tag/v1.0.0)

---

## ✨ Key Features

### 🤖 AI-Powered Food Recognition
- **Instant Analysis:** Snap a photo of any meal to detect ingredients and estimate calories.
- **Smart Correction:** Users can manually correct the AI if it misidentifies an item, and the app recalculates macros instantly.
- **Fallback Mechanism:** Robust error handling ensures the app works even when API limits are reached.

### ☁️ Cloud Integration (Firebase)
- **Real-time Database:** All user data (history, favorites, goals) is synced live across devices using **Cloud Firestore**.
- **Secure Authentication:** User management handled via **Firebase Auth**.
- **Cloud Notifications:** Daily reminders and engagement notifications powered by **Firebase Cloud Messaging (FCM)**.

### 🥗 Smart Recipe Recommendations
- **Dynamic Suggestions:** The app suggests healthy recipes based on the user's *remaining* calories for the day.
- **Dietary Customization:** Supports specific medical needs including **Diabetes-Friendly** (low carb) and **Hypertension (DASH)** diets.
- **Cache System:** Implements local caching to reduce API calls and improve performance.

### 📊 Health & Progress Tracking
- **Interactive Charts:** Visual breakdown of daily intake (Protein, Carbs, Fats).
- **History Log:** A detailed calendar view of all past meals.
- **Hydration Tracker:** Simple tool to log daily water intake.

---

## 📱 Screenshots

| Home Screen | AI Scanning | Recipe Hub |
|:-----------:|:-----------:|:----------:|
| <img src="[https://via.placeholder.com/300x600?text=Home](https://github.com/mohammad-akileh/FitLens/blob/main/assets/Home_screen.jpg)" width="200"> | <img src="https://github.com/mohammad-akileh/FitLens/blob/main/assets/Scan_screen.jpg" width="200"> | <img src="[https://via.placeholder.com/300x600?text=Recipes](https://github.com/mohammad-akileh/FitLens/blob/main/assets/Recipes.jpg)" width="200"> |

---

## 🛠️ Tech Stack

- **Framework:** Flutter (Dart)
- **Backend:** Firebase (Firestore, Auth, Cloud Messaging)
- **APIs:** Edamam Food Database API, Edamam Nutrition Analysis API
- **State Management:** `setState` & `StreamBuilder` (Reactive UI)
- **Local Storage:** `shared_preferences` (for caching and settings)
- **Architecture:** Modular MVC-inspired structure for scalability.

---

## 🚀 Getting Started

To run this project locally, follow these steps:

### Prerequisites
- Flutter SDK
- Dart SDK
- Android Studio / VS Code

### Installation
1. **Clone the repository:**
   ```bash
   git clone [https://github.com/mohammad-akileh/FitLens.git](https://github.com/mohammad-akileh/FitLens.git)
