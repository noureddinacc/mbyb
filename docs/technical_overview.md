# MBYB Technical Overview & Architecture 🏗️

This document provides a deep dive into the technical implementation of the **MBYB** application for professional evaluation.

---

## 1. Architecture Pattern
The application follows a modern **layered architecture** influenced by MVVM (Model-View-ViewModel) and Clean Architecture principles, leveraging **Riverpod** for state management.

- **Presentation Layer (`lib/screens`, `lib/widgets`):** Logic-less UI components that watch/listen to providers.
- **Business Logic Layer (`lib/providers`):** Manages application state, handles asynchronous data streams, and coordinates between UI and Services.
- **Service Layer (`lib/services`):** Encapsulates external interactions (Firebase Auth, Firestore) using the Repository pattern.
- **Data Layer (`lib/models`):** Immutable data classes with factory constructors for JSON/Firestore serialization.

---

## 2. Multi-Tenancy & Data Isolation 🛡️
A core requirement of MBYB is strict isolation between different universities.

### Implementation:
- **Tenant Identification:** Every user profile, book post, and report is tagged with a `universityId`.
- **Auth-Level Binding:** During login/signup, users are bound to a university domain. The `universityId` is persisted in the user's Firestore document.
- **Provider-Level Filtering:** Key providers (like `availableBooksProvider`) watch the `userProfileProvider`. They automatically inject `.where('universityId', isEqualTo: userUniId)` into Firestore queries.
- **Master Admin Bypass:** A specialized check for a hardcoded Master Admin email allows global access, bypassing the `universityId` filters for platform-wide management.

---

## 3. State Management (Riverpod) 🧪
We use **Riverpod 2.x** with a mix of `StreamProvider`, `FutureProvider`, and `NotifierProvider`.

- **`authStateProvider`:** Tracks the Firebase Auth state.
- **`userProfileProvider`:** Fetches and caches the current user's metadata from Firestore.
- **`availableBooksProvider`:** A reactive stream that provides filtered book data based on the user's university and active filters.
- **`isAdminProvider`:** A computed provider that determines if the current user has administrative privileges by scanning global and university-specific admin lists.

---

## 4. Service Layer (Firebase Integration) 🔥
Services are implemented as classes with clear responsibilities:

- **`AuthService`:** Manages sign-in, sign-up, and user blocking logic.
- **`BookService`:** Handles CRUD operations for book listings.
- **`ReportService`:** Manages the lifecycle of user/book reports.
- **`SystemMessageService`:** Handles one-way admin communications and university-scoped broadcasts using Firestore `WriteBatch` for performance.

---

## 5. Routing & Navigation 🧭
The app uses **GoRouter** for declarative routing.

- **Route Guards:** Implementation of a `redirect` logic that checks authentication status and redirects users to `/login` if not authenticated.
- **Deep Linking:** Structured URL patterns (e.g., `/chat/:chatId`) for future-proofing and web support.

---

## 6. UI/UX & Design System 🎨
- **Theming:** A centralized `ThemeData` system supporting dynamic Light/Dark mode switching via `themeProvider`.
- **RTL Support:** Complete Right-to-Left (RTL) support for Arabic, ensured by wrapping the root in `Directionality`.
- **Component Reusability:** Custom widgets like `BookCard` and `ActionPill` ensure visual consistency and reduce code duplication.

---

## 7. Security & Validation ✅
- **Client-Side:** Robust validation logic in `lib/utils/validators.dart` for email domains and password strength.
- **Server-Side:** Firestore Security Rules (configured in Firebase) enforce that users can only read data from their own university and only update their own posts.

---

## 8. Module Breakdown 🧩
- **Auth Module:** Handles registration, login with university selection, and email verification.
- **Marketplace Module:** The core feed, book posting with image support, and filtering.
- **Messaging Module:** Real-time P2P chat with real-time status indicators.
- **Admin Module:** Specialized dashboard for university moderation and system-wide broadcasts.
- **Profile Module:** Management of user settings and "My Posts" tracking.

---

## 9. Technical Highlights for Evaluators
- **Optimistic UI:** Stream-based updates ensure the UI reflects database changes instantly.
- **Batch Processing:** Broadcast messages use `Firestore Batch` to handle mass notifications efficiently.
- **Scalability:** The university-tenant model is designed to support hundreds of institutions without performance degradation.
- **State Decoupling:** Business logic is entirely decoupled from the UI, making the app highly testable.

---
*Document prepared for technical review.*
