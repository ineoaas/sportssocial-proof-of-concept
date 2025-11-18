# SportsSocial – Proof of Concept

SportsSocial is a **prototype social media app for sports**, built as part of my ICT studies at Fontys.  
The goal of the app is to make it easier for people to **discover activities, join groups, and stay updated** with sports events in their community.

>  **Note:** This is a **proof of concept**. The UI and basic navigation are implemented in Flutter, but the backend (Firebase) is not fully connected yet.

---

## Concept

SportsSocial is designed to help users:

- View **announcements** about sports activities (training, matches, events)
- Discover and **join activities**
- See a **schedule** of upcoming events
- Browse **groups** based on sport or location

The focus of this version is on the **app flow, layout, and user experience**, not on production-ready backend logic.

---

## Features (Current State)

Implemented (Front-end / Proof of Concept):

- Multi-screen Flutter app with:
  - Announcements screen
  - Activities creation/join screens
  - Schedule screen
  - Groups screen
  - Login / welcome flow (if included)
- Navigation between main screens
- Basic UI components and layout
- Placeholder logic for creating announcements/activities (local state)

Not fully implemented / Planned:

- Firebase authentication
- Realtime database / Firestore integration
- Persistent storage of activities and announcements
- User accounts, profiles, and roles (e.g. trainer vs player)
- Push notifications

---

## Tech Stack

- **Framework:** Flutter
- **Language:** Dart
- **Architecture:** Proof-of-concept, focused on UI & navigation
- **Planned Backend:** Firebase (Auth + Firestore/Realtime Database)

---

## Getting Started

> This project is intended as a student proof of concept.  
> You can still run the app locally to explore the UI and navigation.

### 1. Prerequisites

- Flutter SDK installed  
- Android Studio or Xcode (for emulator)  
- A connected device or emulator

### 2. Clone the repo

```bash
git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
cd YOUR_REPO_NAME
