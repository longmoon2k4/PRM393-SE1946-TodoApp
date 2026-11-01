# Repository Guidelines

## Project Structure & Module Organization

This is a Flutter/Dart and Spring Boot monorepo. `lib/main.dart` starts the app; shared code lives in `lib/core/`. Features are in `lib/features/auth_and_dashboard/`, `lib/features/task_board_and_filter/`, and `lib/features/task_detail_and_collab/`. Read the area's `REQUIREMENTS.md`; work in your assigned feature and coordinate before changing another feature or shared contracts.

Backend source is in `backend/src/main/java/com/todoapp/api/`; database initialization is in `backend/sql/init.sql`, with API/schema docs in `docs/`. Flutter assets are declared in `pubspec.yaml`. Use `MockRepository.mockTasks` for isolated UI; use `coreTasksProvider` for task state and API/cache integration.

## Build, Test, and Development Commands

Requires Flutter/Dart per `pubspec.yaml` (`>=3.13.0 <4.0.0`), Java 17, Maven, and Docker.

- `flutter pub get` resolves Flutter dependencies.
- Run `dart format lib test`, `flutter analyze`, and `flutter test` to format, lint, and test Flutter code.
- `docker compose -f backend/docker-compose.yml up -d` starts MySQL; `mvn -f backend/pom.xml spring-boot:run` starts the API.
- `flutter run` launches on the selected device; `flutter build apk --debug` builds a debug Android APK.

## Coding Style & Naming Conventions

Follow `flutter_lints` and two-space Dart indentation. Use `snake_case.dart` files, `UpperCamelCase` types, and `lowerCamelCase` members. Keep shared/API logic in `lib/core/`, feature logic in its provider/repository, and screens in `presentation/`; follow existing Java naming.

## Testing Guidelines

Add Flutter tests as `test/*_test.dart` using `flutter_test`. Existing tests cover model serialization and task deadlines; no coverage threshold is set. Cover changed behavior, including loading, empty, error, and offline paths. Backend tests and test dependencies are not configured in `pom.xml` yet.

## Commit & Pull Request Guidelines

Use focused Conventional Commit messages (`feat:`, `fix:`, `docs:`, `chore:`). Work on a personal `feat/*` branch; README documents merging into `dev` and opening a PR from `dev` to `main`. Never push directly to protected `main`. PRs need a change summary, validation results, related issue when applicable, and UI screenshots.

## Security & Configuration Tips

`TaskApiService.defaultBaseUrl` currently uses `10.0.2.2:8080` for all Android targets and `localhost:8080` elsewhere; change the service to a reachable host address for physical Android. Backend `permitAll` and local DB credentials are development-only. Do not commit secrets or machine-specific files such as `android/local.properties`; keep `pubspec.lock` versioned.
