# Smart Classroom Backend API Documentation

## Base URL

http://localhost:3000

## Authentication

Protected APIs require a Firebase ID token.

Header:
Authorization: Bearer YOUR_FIREBASE_ID_TOKEN

Do not share real tokens or passwords.

---

## 1. Sync User

**Method:** POST  
**Endpoint:** `/api/auth/sync`  
**Authentication:** Required

Verifies the Firebase token and synchronizes the user's profile with MongoDB.

## 2. Create Classroom

**Method:** POST  
**Endpoint:** `/api/classrooms`  
**Authentication:** Required  
**Permission:** Teacher only

### Request Body

```json
{
  "name": "BTech CSE",
  "description": "Smart Classroom Project"
}
```

Creates a classroom with a generated classroom code.

## 3. Join Classroom

**Method:** POST  
**Endpoint:** `/api/classrooms/join`  
**Authentication:** Required  
**Permission:** Student only

### Request Body

```json
{
  "code": "YOUR_CLASSROOM_CODE"
}
```

A student joins a classroom using its code. Duplicate joins are rejected.

## 4. Get All Classrooms

**Method:** GET  
**Endpoint:** `/api/classrooms`  
**Authentication:** Required

Returns classrooms associated with the logged-in user.

## 5. Get Classroom Details

**Method:** GET  
**Endpoint:** `/api/classrooms/:id`  
**Authentication:** Required

Replace `:id` with the MongoDB classroom `_id`.

Returns classroom details to an authorized teacher or member student.

## 6. Remove Student

**Method:** DELETE  
**Endpoint:** `/api/classrooms/:id/students`  
**Authentication:** Required  
**Permission:** Classroom owner (teacher) only

### Request Body

```json
{
  "studentUid": "STUDENT_FIREBASE_UID"
}
```

Removes the specified student's UID from the classroom.

---

## Testing Notes

- Use a valid Firebase ID token for protected endpoints.
- Teacher and student permissions are different.
- Use actual MongoDB classroom IDs, not classroom codes, in `:id`.
- Never commit `.env` or Firebase service-account credentials to GitHub.
-