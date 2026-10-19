# Unified Learn

**Learn. Grow. Achieve.**

Unified Learn is a React + Vite frontend for a unified learning and virtual-classroom experience. It brings student and teacher workflows into one responsive interface, with separate role-specific portals and English/Hindi UI support.

## Current frontend features

- Premium responsive landing page with navigation, feature showcases, calls to action, and footer.
- Persistent dark/light theme preference.
- Persistent English (`en`) and Hindi (`hi`) language preference.
- Separate student and teacher login and registration routes.
- Student and teacher workspaces with role-aware navigation.
- Classes, assignments, materials, attendance, timetable/calendar, chat, announcements, notifications, AI Mentor UI, Quiz Generator UI, profile, and settings.
- Mock services isolated under `src/services/mock/` for predictable local interactions.
- Provisional integration handoff in [`docs/FRONTEND_INTEGRATION.md`](docs/FRONTEND_INTEGRATION.md).

## Run locally

Requirements: Node.js compatible with the Vite version in `package.json`, and npm.

```bash
npm install
npm run dev
```

Run the available checks:

```bash
npm run lint
npm run build
```

Vite prints the local development URL after the server starts.

## Role-specific frontend accounts

The current authentication service is a frontend-only fixture:

| Portal | Account ID |
| --- | --- |
| Student | `STU-1001` |
| Teacher | `TCH-2001` |

The current illustrative access code is `learn2026`. These values are hard-coded prototype fixtures, **not production credentials**. Registration only creates a local profile preview. Do not use this authentication for real student data.

## Language and theme

Use the language selector to switch between English and हिन्दी. Theme and language preferences are stored independently in this browser. The appearance can also be changed in the workspace settings; reduce-motion preference is applied across the interface.

## Important implementation boundary

This repository is the **frontend only**. Mock services do not make network requests. Class records, assignment changes, attendance edits, messages, quiz questions, and mentor responses are illustrative local behavior. Camera/microphone controls do not access devices, chat messages are not delivered to classmates, and selected files are not uploaded to a server.

Before production use, replace the mock service adapters with approved backend, authentication, storage, video, and ML integrations. Server-side identity and permissions must be enforced by the backend; frontend route guards are only a user-experience layer.

See [`docs/FRONTEND_INTEGRATION.md`](docs/FRONTEND_INTEGRATION.md) for provisional contracts and team handoff guidance.
