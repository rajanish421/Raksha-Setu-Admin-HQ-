# 🛡️ Raksha Setu — Admin HQ Dashboard

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth%20%7C%20FCM-orange?logo=firebase&logoColor=white" />
  <img src="https://img.shields.io/badge/Platform-Web%20%7C%20Desktop-lightgrey" />
  <img src="https://img.shields.io/badge/Version-1.0.0-green" />
</p>

> **Raksha Setu Admin HQ** is a Flutter-based secure command dashboard built exclusively for Defence HQ administrators. It provides real-time oversight and full control over personnel, security alerts, groups, broadcast notifications, and audit logs — all backed by Firebase.

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Screenshots](#-screenshots)
- [Architecture](#-architecture)
- [Navigation Flow](#-navigation-flow)
- [Firestore Data Schema](#-firestore-data-schema)
- [Folder Structure](#-folder-structure)
- [Tech Stack](#-tech-stack)
- [Environment Setup](#-environment-setup)
- [Running the App](#-running-the-app)
- [Role & Permissions Model](#-role--permissions-model)
- [Logging System](#-logging-system)
- [Notification System](#-notification-system)
- [Contributing](#-contributing)

---

## 🔍 Overview

The **Raksha Setu Admin HQ Dashboard** is the administrative backbone of the Raksha Setu platform. It is a restricted-access web/desktop Flutter application intended only for Defence HQ personnel (`admin` and `superAdmin` roles).

Key responsibilities of this dashboard include:

- **Approving / rejecting / suspending** soldiers and families registered on the Raksha Setu mobile app
- **Monitoring and resolving** real-time security alerts (SOS, Threat, Medical, etc.)
- **Managing defence groups** with role-based officer assignments
- **Broadcasting push notifications** to all users via Firebase Cloud Messaging
- **Auditing all actions** through a multi-category structured logging system
- **Creating and governing** admin accounts (superAdmin only)

---

## ✨ Features

| Module | Description |
|---|---|
| 🔐 **Secure Login** | Firebase Auth with role validation (admin / superAdmin only). Blocks pending or non-admin accounts. |
| 🔑 **Force Password Reset** | New admin accounts must set a new password on first login before accessing the dashboard. |
| 📊 **Dashboard Home** | Live overview cards: Total, Pending, Approved, and Suspended user counts from Firestore. |
| 👥 **User Management** | View all registered users with tabs (All / Approved / Pending / Suspended), search, pagination, approve/reject/suspend, and send FCM push notifications to individual users. |
| 🏢 **Groups Management** | Create, edit, and delete defence groups. Assign commanding officers. Add/remove members. SuperAdmin-gated creation. |
| 🚨 **Security Alerts** | Real-time alert feed (SOS / Threat / Medical / Suspicious / Other) with severity badges, filters by type/status/group, acknowledge & resolve workflows, and alert detail modals. Live badge counter in the sidebar. |
| 🛠️ **Admin Management** | List all admin accounts. SuperAdmin can create new admins (auto-generates temp password, forces reset on first login), suspend/reinstate, delete, and fine-tune per-module permissions. |
| 📜 **System Logs** | Unified log viewer aggregating Admin Logs, User Logs, Alert Logs, and System Logs. Filter by type, date range, and keyword search. View raw JSON details for any log entry. |
| 🔔 **Notifications Center** | Compose and broadcast in-app notifications to all users. View notification history in reverse-chronological order. |

---

## 📸 Screenshots

| Login Screen | Dashboard Home | Security Alerts |
|:---:|:---:|:---:|
| _(login.png)_ | _(dashboard_home.png)_ | _(alerts.png)_ |

| User Management | Admin Management | System Logs |
|:---:|:---:|:---:|
| _(user_management.png)_ | _(admin_management.png)_ | _(logs.png)_ |

> To add real screenshots: create a `screenshots/` directory at the root, save PNG captures there, and replace the placeholder cells above with `![Label](screenshots/filename.png)` Markdown image tags.

---

## 🏗️ Architecture

The project follows a **feature-first layered architecture**. Each feature encapsulates its own screens and services, with shared constants and utilities at the top level.

```
┌─────────────────────────────────────────────────────────────┐
│                        Flutter App                          │
│                                                             │
│  ┌──────────────┐   ┌──────────────────────────────────┐   │
│  │   main.dart  │──▶│         HqDashboardApp            │   │
│  │  (Firebase   │   │  (MaterialApp + AppRouter)        │   │
│  │   + dotenv   │   └──────────────┬───────────────────┘   │
│  │   init)      │                  │                        │
│  └──────────────┘        ┌─────────▼──────────┐            │
│                           │   AppRouter        │            │
│                           │  (Named Routes)    │            │
│                           └──┬──────┬──────────┘            │
│                    ┌─────────▼──┐  ┌▼─────────────────┐    │
│                    │  Auth Layer│  │  Dashboard Shell  │    │
│                    │            │  │  (Sidebar Nav)    │    │
│                    │ • Login    │  │                   │    │
│                    │ • PwReset  │  │  ┌─────────────┐  │    │
│                    └────────────┘  │  │  Home       │  │    │
│                                    │  │  Users      │  │    │
│                    ┌───────────┐   │  │  Groups     │  │    │
│                    │ Services  │   │  │  Alerts     │  │    │
│                    │           │   │  │  Admins     │  │    │
│                    │ • Auth    │◀──│  │  Logs       │  │    │
│                    │ • Log     │   │  │  Notifs     │  │    │
│                    │ • Notif   │   │  └─────────────┘  │    │
│                    │ • FCM     │   └───────────────────┘    │
│                    └─────┬─────┘                            │
└──────────────────────────┼──────────────────────────────────┘
                           │
          ┌────────────────▼──────────────────┐
          │            Firebase               │
          │  ┌──────────┐  ┌──────────────┐  │
          │  │   Auth   │  │  Firestore   │  │
          │  └──────────┘  └──────────────┘  │
          │  ┌─────────────────────────────┐  │
          │  │  Firebase Cloud Messaging   │  │
          │  └─────────────────────────────┘  │
          └───────────────────────────────────┘
```

---

## 🧭 Navigation Flow

```mermaid
flowchart TD
    A([App Start]) --> B[Load .env\nInit Firebase]
    B --> C[/login route\nAdminLoginScreen]

    C -->|Invalid credentials\nor non-admin role| C
    C -->|mustResetPassword = true| D[/force-reset\nForcePasswordResetScreen]
    C -->|Approved admin\nnormal login| E[/dashboard\nDashboardShell]

    D -->|Password updated\nFirestore flag cleared| E

    E --> F{Sidebar Selection}

    F -->|0| G[Dashboard Home\nLive user counts]
    F -->|1| H[User Management\nApprove · Reject · Suspend · Notify]
    F -->|2| I[Groups Management\nCreate · Edit · Members · Officers]
    F -->|3| J[Security Alerts\nSOS · Threat · Medical · Suspicious]
    F -->|4| K[Admin Management\nCreate · Suspend · Permissions]
    F -->|5| L[System Logs\nAdmin · User · Alert · System]
    F -->|6| M[Notifications Center\nBroadcast · History]
    F -->|Logout| C
```

---

## 🗄️ Firestore Data Schema

```mermaid
erDiagram
    USERS {
        string userId PK
        string fullName
        string phone
        string serviceNumber
        string role "user | admin | superAdmin"
        string status "pending | approved | suspended | rejected"
        bool mustResetPassword
        map permissions
        timestamp createdAt
        string fcmToken
    }

    GROUPS {
        string groupId PK
        string name
        string commandingOfficerUid
        array memberUids
        timestamp createdAt
    }

    ALERTS {
        string alertId PK
        string type "SOS | Threat | Medical | Suspicious | Other"
        string title
        string message
        string senderUid
        string senderName
        string senderRole
        string groupId
        string groupName
        string status "pending | acknowledged | resolved"
        geopoint location
        timestamp timestamp
    }

    NOTIFICATIONS {
        string notifId PK
        string title
        string message
        array readBy
        number timestamp
    }

    ADMIN_LOGS {
        string logId PK
        string adminUid
        string adminName
        string action
        string targetUid
        string targetName
        string groupId
        string groupName
        map meta
        timestamp timestamp
    }

    USER_LOGS {
        string logId PK
        string uid
        string name
        string role
        string action
        map meta
        timestamp timestamp
    }

    ALERT_LOGS {
        string logId PK
        string alertId
        string action
        string performedByUid
        string performedBy
        map meta
        timestamp timestamp
    }

    SYSTEM_LOGS {
        string logId PK
        string level "INFO | WARN | ERROR | CRITICAL"
        string message
        map info
        timestamp timestamp
    }

    USERS ||--o{ GROUPS : "belongs to"
    USERS ||--o{ ALERTS : "sends"
    USERS ||--o{ ADMIN_LOGS : "is target of"
    ALERTS ||--o{ ALERT_LOGS : "has"
```

---

## 📁 Folder Structure

```
lib/
├── main.dart                          # App entry point (Firebase + dotenv init)
│
├── constant/
│   ├── app_colors.dart                # Colour palette (dark green + gold theme)
│   └── app_theme.dart                 # MaterialApp ThemeData configuration
│
├── utils/
│   ├── app_router.dart                # Named route generator
│   └── route_names.dart               # Route name constants
│
└── features/
    ├── auth/
    │   ├── screens/
    │   │   ├── admin_login_screen.dart          # HQ Secure Login form
    │   │   └── force_password_reset_screen.dart # First-login password reset
    │   └── services/
    │       └── admin_auth_service.dart          # Firebase Auth + role check (Singleton)
    │
    ├── dashboard/
    │   ├── dashboard_shell.dart                 # Sidebar shell + screen switcher
    │   ├── screens/
    │   │   ├── dashboard_home_screen.dart        # Overview metric cards
    │   │   ├── user_management_screen.dart       # User list, approve/reject/suspend/notify
    │   │   ├── groups_screen.dart                # Group CRUD + members
    │   │   ├── alerts_screen.dart                # Real-time security alerts
    │   │   ├── admin_management_screen.dart      # Admin CRUD + permissions
    │   │   ├── logs_screen.dart                  # Unified audit log viewer
    │   │   ├── notifications_screen.dart         # Broadcast notifications
    │   │   └── pending_users_screen.dart         # (Legacy – currently commented out)
    │   └── services/
    │       ├── log_service.dart                  # Structured logging (4 collections)
    │       ├── send_notification_services.dart   # FCM HTTP v1 push sender
    │       └── get_user_fcm_token.dart           # Fetch device FCM token from Firestore
    │
    └── notification/
        ├── serverKey.dart                        # OAuth2 service-account token provider
        └── services/
            └── notification_services.dart        # Local notifications + FCM init
```

---

## 🔧 Tech Stack

| Layer | Technology |
|---|---|
| **UI Framework** | Flutter (Dart 3.x) |
| **Authentication** | Firebase Authentication |
| **Database** | Cloud Firestore (NoSQL) |
| **Push Notifications** | Firebase Cloud Messaging (FCM) v1 HTTP API |
| **OAuth2 (FCM Auth)** | `googleapis_auth` — Service Account credentials |
| **Local Notifications** | `flutter_local_notifications` |
| **Environment Config** | `flutter_dotenv` — `.env` file |
| **HTTP Client** | `http` package |
| **Date Formatting** | `intl` |
| **URL Handling** | `url_launcher` |
| **App Settings** | `app_settings` |
| **Theme** | Dark military theme (deep green `#0B3D2E` + gold `#F9B233`) |
| **Target Platforms** | Web, Windows, macOS, Linux |

---

## ⚙️ Environment Setup

All Firebase credentials and service account keys are loaded from a `.env` file at runtime (never hard-coded).

### 1. Clone the repository

```bash
git clone https://github.com/rajanish421/Raksha-Setu-Admin-HQ-.git
cd Raksha-Setu-Admin-HQ-
```

### 2. Create your `.env` file

```bash
cp .env.example .env
```

Then open `.env` and fill in all required values:

```dotenv
# ── Firebase Web Options ────────────────────────────────────
FIREBASE_WEB_API_KEY=AIza...
FIREBASE_WEB_APP_ID=1:123456789:web:abc123
FIREBASE_WEB_MESSAGING_SENDER_ID=123456789
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_WEB_AUTH_DOMAIN=your-project-id.firebaseapp.com
FIREBASE_WEB_STORAGE_BUCKET=your-project-id.appspot.com
FIREBASE_WEB_MEASUREMENT_ID=G-XXXXXXXXXX

# ── Firebase Service Account (for FCM OAuth2 token) ─────────
FIREBASE_SA_TYPE=service_account
FIREBASE_SA_PRIVATE_KEY_ID=abc123...
FIREBASE_SA_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\nMII...\n-----END PRIVATE KEY-----\n
FIREBASE_SA_CLIENT_EMAIL=firebase-adminsdk-xxxx@your-project-id.iam.gserviceaccount.com
FIREBASE_SA_CLIENT_ID=1234567890
FIREBASE_SA_AUTH_URI=https://accounts.google.com/o/oauth2/auth
FIREBASE_SA_TOKEN_URI=https://oauth2.googleapis.com/token
FIREBASE_SA_AUTH_PROVIDER_X509_CERT_URL=https://www.googleapis.com/oauth2/v1/certs
FIREBASE_SA_CLIENT_X509_CERT_URL=https://www.googleapis.com/robot/v1/metadata/x509/...
FIREBASE_SA_UNIVERSE_DOMAIN=googleapis.com
```

> ⚠️ **Security**: Never commit your `.env` file. It is already listed in `.gitignore`.

> 📝 **Private key format**: In the `.env` file the private key must be stored as a **single line** with literal `\n` sequences where newlines appear (i.e. `-----BEGIN PRIVATE KEY-----\nMII...\n-----END PRIVATE KEY-----\n`). The app calls `.replaceAll(r'\\n', '\n')` at runtime to restore the real newlines before using the key. Do **not** use actual multi-line values in the `.env` file.

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Configure Firebase

Ensure `lib/firebase_options.dart` is generated for your Firebase project using the FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

---

## 🚀 Running the App

```bash
# Web (recommended for this dashboard)
flutter run -d chrome

# macOS
flutter run -d macos

# Windows
flutter run -d windows

# Linux
flutter run -d linux
```

---

## 🔐 Role & Permissions Model

```
┌──────────────┬─────────────────────────────────────────────────────────┐
│     Role     │  Capabilities                                           │
├──────────────┼─────────────────────────────────────────────────────────┤
│  superAdmin  │  Full access. Can create/delete/suspend admins.         │
│              │  Cannot be modified by other admins (protected).        │
├──────────────┼─────────────────────────────────────────────────────────┤
│    admin     │  Access governed by per-module permissions set by       │
│              │  superAdmin. Modules: users, groups, alerts, logs,      │
│              │  adminManagement (read/write toggles per module).       │
├──────────────┼─────────────────────────────────────────────────────────┤
│     user     │  No dashboard access. Mobile app only.                  │
└──────────────┴─────────────────────────────────────────────────────────┘
```

**User status lifecycle:**

```
register ──▶ pending ──▶ approved ──▶ suspended
                  └──▶ rejected
```

**Admin account lifecycle (SuperAdmin only):**

```
createAdmin ──▶ active (mustResetPassword=true)
                  │
                  ▼ (first login)
              password reset ──▶ active
                  │
                  ▼
              suspended  ──▶  reinstated ──▶ active
                  │
                  ▼
              deleted
```

---

## 📜 Logging System

All significant actions are automatically recorded into structured Firestore collections.

| Collection | Triggered By | Fields |
|---|---|---|
| `adminLogs` | Any admin action (approve, suspend, create, etc.) | `adminUid`, `adminName`, `action`, `targetUid`, `targetName`, `groupId`, `meta`, `timestamp` |
| `userLogs` | User events (register, login, password change) | `uid`, `name`, `role`, `action`, `meta`, `timestamp` |
| `alertLogs` | Alert state changes (acknowledge, resolve) | `alertId`, `action`, `performedByUid`, `performedBy`, `meta`, `timestamp` |
| `systemLogs` | Internal errors / system events | `level` (INFO/WARN/ERROR/CRITICAL), `message`, `info`, `timestamp` |

The **Logs screen** merges all four collections, sorts by timestamp, and supports filtering by type and keyword search with a raw JSON detail modal.

---

## 🔔 Notification System

Push notifications are sent using the **FCM HTTP v1 API** with OAuth2 authentication via a Firebase Service Account.

```
Admin triggers send
       │
       ▼
SendNotificationServices.sendUserChangeStatusNotification()
       │
       ▼
ServerKey.getServerKey()  ──▶  googleapis_auth OAuth2
       │                       (ServiceAccountCredentials)
       ▼
POST https://fcm.googleapis.com/v1/projects/{id}/messages:send
       │
       ▼
FCM ──▶ User device (Android HIGH priority / iOS alert)
```

Local notifications on **Android** use `flutter_local_notifications` with a `high_importance_channel` for heads-up display. iOS foreground notifications are handled via `setForegroundNotificationPresentationOptions`.

---

## 🎨 Design System

| Token | Value | Usage |
|---|---|---|
| `primary` | `#0B3D2E` | Sidebar background, accents |
| `primaryLight` | `#145C41` | Borders, hover states |
| `accent` | `#F9B233` | Buttons, badges, highlights (gold) |
| `background` | `#050B0A` | App background |
| `surface` | `#101818` | Cards, modals |
| `surfaceLight` | `#1C2626` | Input fields, dropdowns |
| `textPrimary` | `#FFFFFF` | Primary text |
| `textSecondary` | `#B0B9B8` | Labels, secondary info |
| `danger` | `#EF476F` | Delete, reject, error |
| `success` | `#06D6A0` | Approve, resolve, success |

---

## 🤝 Contributing

This is a private Defence-sector project. If you are an authorised contributor:

1. Fork or branch from `main`
2. Follow existing naming conventions (feature-first folder structure)
3. Log all significant actions using `LogService`
4. Never commit `.env` or `firebase_options.dart` with real credentials
5. Test role-based flows for both `admin` and `superAdmin` accounts
6. Submit a pull request with a clear description of changes

---

## 📄 License

This project is proprietary and intended for authorised Defence HQ use only. Unauthorised access, distribution, or modification is prohibited.

---

<p align="center">
  Built with ❤️ for the security of those who protect us 🇮🇳
</p>
