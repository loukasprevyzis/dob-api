# dob-api

A simple Go HTTP API to store users' dates of birth and respond with personalized birthday messages.

## Overview

This API provides two main endpoints:

- **PUT /hello/{username}**: Stores or updates the user's date of birth.
  - Username must contain **letters only** (no digits or symbols).
  - The date of birth must be in the format `YYYY-MM-DD` and must be **a past date**.
  - Returns HTTP `204 No Content` on success.

- **GET /hello/{username}**: Returns a personalized birthday message.
  - If today is the user's birthday, responds with `"Hello, {username}! Happy birthday!"`.
  - Otherwise, responds with `"Hello, {username}! Your birthday is in X day(s)"`.
  - Returns `404 Not Found` if the user does not exist.

- Unsupported HTTP methods will return `405 Method Not Allowed`.

## Code Explanation

- **Username Validation**: Uses a regular expression (`^[A-Za-z]+$`) to ensure usernames only contain letters.

- **Routing Logic**:
  The main handler `HelloHandler` extracts the username from the URL path `/hello/{username}` and validates it.
  It then dispatches the request based on HTTP method:
  - `PUT` calls `handlePut`
  - `GET` calls `handleGet`
  - Other methods return `405 Method Not Allowed`

- **PUT /hello/{username}** (`handlePut`):
  - Parses JSON payload with `"dateOfBirth"`.
  - Validates the date format and ensures the date is in the past.
  - Inserts or updates the user record in the database with SQL `INSERT ... ON CONFLICT DO UPDATE`.
  - Returns `204 No Content` on success, or appropriate error codes.

- **GET /hello/{username}** (`handleGet`):
  - Queries the database for the user's date of birth (case-insensitive username match).
  - If user not found, returns `404 Not Found`.
  - Calculates the next birthday date based on the current date.
  - Responds with a JSON message wishing happy birthday if today, or indicating days remaining until next birthday.

- **Database Access**:
  The `App` struct wraps the `*sql.DB` connection used to query and update the database.