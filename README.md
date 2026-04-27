# MBYB (My Book Your Book) 📚

**MBYB** is a modern, peer-to-peer mobile platform designed specifically for university students to exchange, sell, or donate academic books. It fosters a collaborative campus community by making educational resources more accessible and affordable.

---

## 🌟 Key Features

### 🏢 Multi-University Data Isolation
The platform supports multiple universities with strict data tenant isolation. Users only see posts, reports, and messages relevant to their specific institution, while a Master Admin retains global oversight.

### 📖 Book Marketplace
- **Post Books:** Users can list books they have (Available) or books they need (Wanted).
- **Details:** Includes faculty, condition, description, and exchange preferences.
- **Smart Filtering:** Filter books by faculty, post type, or search queries.

### 💬 Real-Time Communication
- **In-App Chat:** Secure real-time messaging between interested parties.
- **Chat History:** Persistent conversation logs to track exchange agreements.

### 🛡️ Moderation & Safety
- **Reporting System:** Users can report inappropriate posts or suspicious behavior.
- **Admin Panel:** University Admins can review reports, block/unblock users, and manage campus-specific content.
- **Master Admin:** Global control for platform-wide management.

### 📢 Institutional Broadcasts
- Admins can send real-time announcements (Broadcasts) to all students within their university.
- Master Admin can send global broadcasts to the entire user base.

### 🎨 Premium UI/UX
- **Modern Design:** Sleek, glassmorphic interface with smooth transitions.
- **Dynamic Theming:** Full support for both Light and Dark modes.
- **Arabic Support:** Complete RTL (Right-to-Left) localization.

---

## 🚀 Tech Stack

- **Framework:** [Flutter](https://flutter.dev/)
- **State Management:** [Riverpod](https://riverpod.dev/)
- **Backend:** [Firebase](https://firebase.google.com/)
  - **Authentication:** University email validation with domain-specific rules.
  - **Cloud Firestore:** Scalable NoSQL database with strict security rules.
- **Navigation:** [GoRouter](https://pub.dev/packages/go_router)
- **Localization:** Arabic (RTL)

---

## 🛠️ Getting Started

### Prerequisites
- Flutter SDK (Latest Stable)
- Android Studio / VS Code
- Firebase Account

### Installation
1. **Clone the repository:**
   ```bash
   git clone https://github.com/noureddinacc/mbyb.git
   ```
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Configure Firebase:**
   - Create a new Firebase project.
   - Add Android/iOS/Web apps to the project.
   - Download and place `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) in the appropriate directories.
4. **Run the app:**
   ```bash
   flutter run
   ```

---

## ⚖️ License
This project is developed as part of a graduation requirement. All rights reserved.

---

## 👥 Contributors
- **Noureddin** - Lead Developer

---
*Created with ❤️ *
