
---

## 🔷 1. Core Purpose of BMC_App

Your app should allow hospital staff (doctors, nurses, admin) to:

* Access personal records
* Manage schedules
* Request leave
* View announcements
* Handle internal communication

Think of it like an internal “hospital dashboard.”

---

## 🔷 2. Key Features to Include

### 👤 Authentication System

* Login (email + password or staff ID)
* Role-based access (Doctor, Nurse, Admin)

### 📅 Duty / Shift Management

* View assigned shifts
* Request shift swaps
* Notifications for updates

### 📝 Leave Management

* Apply for leave
* Track approval status
* Admin approval panel

### 💬 Internal Communication

* Messaging between staff
* Department announcements

### 📂 Staff Profile

* View/update personal info
* Upload documents (certificates, ID)

### 📊 Dashboard

* Quick overview:

    * Upcoming shifts
    * Pending requests

---

## 🔷 3. App Structure (Flutter)

```
lib/
│── main.dart
│── core/
│   ├── constants/
│   ├── utils/
│   ├── services/ (API, Auth)
│
│── features/
│   ├── authentication/
│   ├── dashboard/
│   ├── leave/
│   ├── schedule/
│   ├── profile/
│
│── shared/
│   ├── models/
```

---

## 🔷 4. Tech Usage

* Flutter
* State Management: using Provider

---

## 🔷 5. Screens Designed

Start simple:

1. Splash Screen
2. Login Screen
3. Dashboard
4. Profile Screen
5. Leave Request Screen
6. Shift Schedule Screen
7. Notifications Page

---
