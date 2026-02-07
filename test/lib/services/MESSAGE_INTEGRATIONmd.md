MESSAGE_INTEGRATION# Offline & Mesh Networking Integration Specification  
**School Management System (Flutter Frontend + Dart Backend)**

## 1. Purpose
Integrate **offline-first messaging and file sharing** using **mesh networking** into an existing School Management System (SMS) to support:
- Students
- Teachers
- Administrators  
especially in **rural areas and emergency situations**, with **no paid APIs** and **no mobile provider charges**.

---

## 2. Core Requirements

### Functional
- Offline text messaging
- Offline file sharing (PDFs, images, audio)
- Store-and-forward mesh delivery
- Emergency broadcast messages
- Automatic network switching
- Android + Desktop support
- Integration with existing user roles

### Non-Functional
- No SMS
- No paid APIs
- Flutter-based frontend
- Dart-based backend server
- Secure (end-to-end encryption)
- Low power usage
- Works without SIM cards

---

## 3. Supported Communication Modes (Priority Order)

1. **Mesh Network (Offline)**
   - Bluetooth
   - Wi-Fi Direct
2. **Local Network (LAN)**
   - School Wi-Fi
   - Local hotspot
3. **Internet (Optional Sync)**
   - Self-hosted Dart server
   - WebSocket connections

The app must automatically choose the best available mode.

---

## 4. System Architecture Overview

Flutter App
│
├── Communication Module
│ ├── Mesh Transport (Android Native)
│ │ ├── Bluetooth
│ │ ├── Wi-Fi Direct
│ │ └── Relay / Forwarding
│ │
│ ├── Internet Transport
│ │ └── WebSocket Client
│ │
│ └── Unified Messaging API
│
├── Security Layer
│ ├── Device Identity
│ ├── Encryption
│ └── Authentication
│
├── Local Storage
│ ├── Messages
│ ├── Files
│ └── Delivery Status
│
└── Dart Backend Server
├── WebSocket Gateway
├── Message Sync
└── Desktop/Web Clients


---

## 5. Identity & User Mapping

### Device Identity
Each device generates a persistent ID:

device_id = SHA256(device_hardware_id + school_id)


### User Mapping
- device_id → student_id / teacher_id / admin_id
- No phone numbers
- No SIM dependency

---

## 6. Message Data Model

### Message Object
```json
{
  "message_id": "uuid",
  "from_device": "device_id",
  "to": "user_id | group_id",
  "type": "text | file | audio | alert",
  "timestamp": "UTC_ISO",
  "ttl_hours": 48,
  "hop_count": 0,
  "encrypted_payload": "base64"
}

Rules
Messages are stored locally until delivered

Forward messages to newly discovered peers

Drop messages after TTL expiration

Prevent duplication using message_id

7. Mesh Networking Logic
Store-and-Forward Algorithm
Discover nearby peers

Exchange message inventories

Send missing messages

Increment hop count

Respect TTL and hop limits

Relay Conditions
App installed

Bluetooth/Wi-Fi enabled

Battery above safe threshold

8. File Transfer Strategy
Split files into small chunks (e.g., 50KB)

Send chunks sequentially

Resume interrupted transfers

Prioritize text over files

Example:

file.pdf → 50KB chunks → encrypted → forwarded
9. Security Requirements
End-to-end encryption

Device-based key pairs

School-level trust keys

Encrypted local storage

No plaintext messages at rest or in transit

10. Flutter Responsibilities
UI / UX

Message orchestration

Local database (offline)

Encryption / decryption

Platform channel communication

Platform Channels
Flutter must call native Android code for:

Peer discovery

Data transmission

Background services

11. Android Native Responsibilities
Bluetooth discovery

Wi-Fi Direct connections

Background message relay

Low-level data transfer

Battery optimization handling

12. Dart Backend Server (Optional, Free)
Purpose
Sync messages when internet exists

Support desktop/web clients

Act as a bridge, not a dependency

Features
WebSocket server

Message queue

Role-based access

No SMS, no third-party APIs

13. Desktop Integration
Preferred Option
Web application

Connects to Dart backend

Syncs with mesh when users go online

Optional
Local school server for LAN-only operation

14. Emergency Mode
When activated:

Disable file transfers

Prioritize alerts

Increase relay frequency

Allow broadcast to all nearby devices

15. Voice Communication Policy
Not Supported
Live voice calls (VoIP)

Supported
Voice notes

Audio announcements

Push-to-talk style messages

Reason:
Mesh networks cannot guarantee low-latency audio streams.

16. MVP Scope (Recommended)
Phase 1:

Text messaging

Offline mesh relay

Teacher ↔ Student chat

Emergency alerts

Phase 2:

File sharing

Voice notes

Desktop sync

Phase 3:

City-scale optimization

Analytics

Multi-school federation

17. Constraints & Assumptions
Android devices required for mesh

Flutter platform channels allowed

Users install the app

High user density improves performance

18. Success Criteria
Messaging works without internet

No carrier charges incurred

Messages eventually deliver

Secure and reliable under outages

Seamless integration with existing SMS

19. Guiding Principle
Text first. Offline always. Internet when available.