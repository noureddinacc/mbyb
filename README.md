# My Book Your Book (MBYB)

A secure, gated mobile marketplace for academic textbook exchange, built exclusively for verified Al-al Bayt University (AABU) students.

Graduation Project · Al-al Bayt University · Supervised by Dr. Laith Abualigah

---

## The Problem

AABU students were relying on unmoderated Facebook groups and WhatsApp channels to exchange textbooks, exposing themselves to spam, fake accounts, and public privacy leaks like phone numbers posted openly. There was no accountability, no structure, and no safety.

## The Solution

MBYB replaces that chaos with a Gated Community app: only verified AABU students can enter, every interaction is structured, and no direct contact happens until both parties explicitly agree.

---

## Key Features

### Domain-Gated Authentication
Access is restricted to @st.aabu.edu.jo email addresses only. A Regex validator rejects any non-institutional email at the registration step. The Student ID is automatically extracted from the email string and used as the public username, so no personal names or phone numbers are ever exposed.

### The Handshake Protocol
The core innovation of MBYB. No user can message another directly. Instead:
1. A student requests a book (or offers to fulfill a "Wanted" listing)
2. A Pending request document is created in Firestore
3. The publisher receives a real-time contextual notification
4. Only if the publisher approves does the system generate a secure, private chat room
5. If declined, the flow terminates and no unsolicited messages ever reach a user

This protocol operates bi-directionally for both supply (Free/Exchange posts) and demand (Wanted posts).

### Dynamic Marketplace Feed
- Real-time listing updates via Cloud Firestore WebSocket streams, no manual refresh needed
- Color-coded post types: green for supply (Free books), purple for demand (Wanted books)
- Multi-criteria filtering by Faculty and Post Type via a responsive Bottom Sheet

### Secure Peer-to-Peer Chat
- Chat rooms are generated only after Handshake approval
- Participants are identified by Student ID only, never by name or phone number
- Automated transaction closure footer creates a digital audit trail

### Admin Moderation Dashboard
- Aggregates community-generated reports on users and listings
- Administrators can send direct warnings, review full chat logs, or issue permanent platform bans
- Broadcast module for system-wide announcements to all registered students

### Hard-Lock Blocked Screen
When a user's isBlocked flag is toggled in Firebase, all app navigation is immediately intercepted and replaced with a restriction screen. Only the logout action remains available.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart), cross-platform iOS and Android |
| Authentication | Firebase Auth (JWT, session management) |
| Database | Cloud Firestore (NoSQL, real-time WebSockets) |
| Storage | Firebase Storage |
| Security | Firebase Security Rules (server-side enforcement) |
| UI | Material Design 3 with Arabic RTL support |
| Methodology | Agile SDLC, 5 iterative sprints |

---

## Architecture

```
Client (Flutter)
    └── App Screens: Auth, Home, Chat, Requests, Admin
         └── State Management and Logic
              ├── Firebase Auth       → JWT token generation
              ├── Firebase Security Rules → Validates token + isBlocked flag
              └── Cloud Firestore     → Real-time data read/write
```

Firestore Collections:
- users: uid, studentId, email, role
- books: bookId, publisherId, title, condition, postType, status
- requests: requestId, bookId, requesterId, publisherId, status
- chats: chatId (composite), participants array, messages sub-collection

---

## Security

Security is enforced server-side, not client-side:
- Only authenticated users can read the books collection
- A user can only write to requests if their requesterId matches their Auth token
- Chat documents can only be queried if the user's UID exists in that chat's participants array
- Result: 100% of unauthorized data mutations rejected in security testing

---

## Development Sprints

| Sprint | Focus |
|---|---|
| 1 | Architecture and UI Prototyping |
| 2 | Firebase Auth and Domain Validation |
| 3 | Firestore Schema and Marketplace Feed |
| 4 | Handshake Protocol and Real-Time Chat |
| 5 | Admin Dashboard, Testing and UAT |

---

## Future Roadmap

- Image Uploads: book cover photos via Firebase Storage with client-side compression
- AI Content Moderation: Google Cloud Vision API to flag inappropriate uploads automatically
- Algorithmic Matchmaking: push notifications when a new listing matches an active Wanted request
- Peer Reputation System: post-exchange rating scale to build long-term community trust

---

## Authors

- Noureddine Mahmoud Al-Issa · [github.com/noureddinacc](https://github.com/noureddinacc)
- Muhannad Samer Al-Basha

Supervisor: Dr. Laith Abualigah · Al-al Bayt University, Jordan
