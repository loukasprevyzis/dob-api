## Testing

The tests in `dob-api/main_test.go` cover the following behaviors of the `helloHandler` in `main.go`:

- **PUT /hello/<username>**
  - Saves a new user's date of birth (DOB) to the database.
  - Updates the DOB if the username already exists.
  - Validates that the username contains only letters.
  - Validates that the DOB is in the correct format (`YYYY-MM-DD`) and is a past date.
  - Returns `204 No Content` on success.
  - Returns appropriate errors for invalid input or database failures.

- **GET /hello/<username>**
  - Retrieves the user's DOB from the database.
  - Returns a birthday message with the number of days until their next birthday.
  - Returns a special greeting if today *is* their birthday.
  - Returns `404 Not Found` if the user does not exist.
  - Returns appropriate errors for database failures or invalid username formats.

- **Username Validation**
  - Ensures usernames only contain alphabetic characters.

- **Birthday Message Logic**
  - Confirms that the message correctly distinguishes between a birthday today and upcoming birthdays.

Each test directly corresponds to a specific branch or validation in the `helloHandler` function, ensuring thorough coverage of request handling, input validation, database interaction, and response formatting.


- **GET /hello/<username> (Future Birthday)**
  - Checks that the response returns the correct number of days until the next birthday when the birthday is upcoming (not today).

- **PUT /hello/<username> (Empty Body)**
  - Ensures that requests with an empty or missing JSON body return a `400 Bad Request` error.

- **GET /hello/ (Invalid Username Format)**
	- Validates that usernames containing non-alphabetic characters return a `400 Bad Request` error, ensuring proper input sanitation on retrieval requests.