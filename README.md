# 📱 Calisthenics App (MVP)

A Flutter-based mobile application for listing and exploring bodyweight calisthenics exercises. Focused on discovery and favoriting exercises with clean filtering options.

## 🚀 Features (MVP)

- **Exercise Listing**: Browse exercises by skill level (Beginner / Intermediate / Advanced)
- **Muscle Group Filtering**: Filter exercises by target muscle groups (Chest, Back, Shoulders, Legs, Core)
- **Exercise Detail Screen**: View exercise information including difficulty, target muscles, and description
- **Favorites**: Add/remove exercises to/from favorites with local storage
- **Clean Architecture + Riverpod**: State management with separation of concerns

## 🧱 Project Architecture

The project follows Clean Architecture principles with clear separation of layers:

- **domain**: Contains entities (Exercise), enums (ExerciseLevel, MuscleGroup, DifficultyLevel), and business logic interfaces
- **data**: Implements repositories with dummy data for local storage and exercise retrieval
- **presentation**: UI layer with screens, widgets, providers (Riverpod), routes, and theming

## 🗂️ Folder Structure

```
lib/
├── domain/
│   ├── models/
│   ├── enums/
│   └── repositories/
├── data/
│   ├── repositories/
│   └── local_storage/
├── presentation/
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── exercise_detail_screen.dart
│   │   └── favorites_screen.dart
│   ├── widgets/
│   │   └── exercise_card.dart
│   ├── providers/
│   ├── routes/
│   │   └── app_routes.dart
│   └── theme/
│       └── app_theme.dart
└── app/
    └── main.dart
```

## 🛠️ Tech Stack

- **Flutter**: UI framework for cross-platform mobile development
- **Dart**: Programming language
- **Riverpod**: State management and dependency injection
- **Clean Architecture**: Software design pattern for maintainability

## 🧩 Future Improvements

- Workout programs and routines
- AI-based exercise suggestions
- User profiles and authentication
- Progress tracking and analytics
- Offline mode and data synchronization

## ▶️ Getting Started

1. Ensure Flutter is installed on your system
2. Clone the repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the application on a connected device or emulator
