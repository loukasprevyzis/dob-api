package api

import (
	"bytes"
	"database/sql"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
)

// App holds the DB connection
type App struct {
	db *sql.DB
}

// setupTestApp creates App with sqlmock
func setupTestApp(t *testing.T) (*App, sqlmock.Sqlmock) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to open sqlmock database: %v", err)
	}
	return &App{db: db}, mock
}

// Test PUT with invalid username format (contains digits or symbols)
func TestHelloHandler_Put_InvalidUsername(t *testing.T) {
	app, _ := setupTestApp(t)

	reqBody := []byte(`{"dateOfBirth":"1990-05-20"}`)
	req := httptest.NewRequest(http.MethodPut, "/hello/user123!", bytes.NewBuffer(reqBody))
	w := httptest.NewRecorder()

	app.HelloHandler(w, req)
	res := w.Result()

	if res.StatusCode != http.StatusBadRequest {
		t.Errorf("expected status 400 Bad Request for invalid username, got %d", res.StatusCode)
	}
}

// Test PUT with invalid date format
func TestHelloHandler_Put_InvalidDateFormat(t *testing.T) {
	app, _ := setupTestApp(t)

	reqBody := []byte(`{"dateOfBirth":"20-05-1990"}`) // wrong format
	req := httptest.NewRequest(http.MethodPut, "/hello/testuser", bytes.NewBuffer(reqBody))
	w := httptest.NewRecorder()

	app.HelloHandler(w, req)
	res := w.Result()

	if res.StatusCode != http.StatusBadRequest {
		t.Errorf("expected status 400 Bad Request for invalid date format, got %d", res.StatusCode)
	}
}

// Test PUT with date of birth in the future
func TestHelloHandler_Put_FutureDOB(t *testing.T) {
	app, _ := setupTestApp(t)

	futureDate := time.Now().AddDate(1, 0, 0).Format("2006-01-02")
	reqBody := []byte(fmt.Sprintf(`{"dateOfBirth":"%s"}`, futureDate))
	req := httptest.NewRequest(http.MethodPut, "/hello/testuser", bytes.NewBuffer(reqBody))
	w := httptest.NewRecorder()

	app.HelloHandler(w, req)
	res := w.Result()

	if res.StatusCode != http.StatusBadRequest {
		t.Errorf("expected status 400 Bad Request for future DOB, got %d", res.StatusCode)
	}
}

// Test GET user found with birthday today
func TestHelloHandler_Get_BirthdayToday(t *testing.T) {
	app, mock := setupTestApp(t)

	today := time.Now().Format("2006-01-02")
	todayTime, _ := time.Parse("2006-01-02", today)

	mock.ExpectQuery(`SELECT date_of_birth FROM users WHERE username = \$1`).
		WithArgs("testuser").
		WillReturnRows(sqlmock.NewRows([]string{"date_of_birth"}).AddRow(todayTime))

	req := httptest.NewRequest(http.MethodGet, "/hello/testuser", nil)
	w := httptest.NewRecorder()

	app.HelloHandler(w, req)
	res := w.Result()

	if res.StatusCode != http.StatusOK {
		t.Errorf("expected status 200 OK, got %d", res.StatusCode)
	}

	body := w.Body.String()
	if !strings.Contains(body, "Happy birthday!") {
		t.Errorf("expected message to contain 'Happy birthday!', got %s", body)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("unfulfilled expectations: %v", err)
	}
}

// Test unsupported HTTP methods
func TestHelloHandler_UnsupportedMethods(t *testing.T) {
	app, _ := setupTestApp(t)

	req := httptest.NewRequest(http.MethodPost, "/hello/testuser", nil)
	w := httptest.NewRecorder()

	app.HelloHandler(w, req)
	res := w.Result()

	if res.StatusCode != http.StatusMethodNotAllowed {
		t.Errorf("expected status 405 Method Not Allowed, got %d", res.StatusCode)
	}
}

// Test PUT /hello/<username> with valid payload
func TestHelloHandler_Put_ValidDOB(t *testing.T) {
	app, mock := setupTestApp(t)
	mock.ExpectExec(`INSERT INTO users`).
		WithArgs("testuser", sqlmock.AnyArg()).
		WillReturnResult(sqlmock.NewResult(1, 1))

	reqBody := []byte(`{"dateOfBirth":"1990-05-20"}`)
	req := httptest.NewRequest(http.MethodPut, "/hello/testuser", bytes.NewBuffer(reqBody))
	w := httptest.NewRecorder()

	app.HelloHandler(w, req)
	res := w.Result()

	if res.StatusCode != http.StatusNoContent {
		t.Errorf("expected status 204 No Content, got %d", res.StatusCode)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("unfulfilled expectations: %v", err)
	}
}

// Test GET /hello/<username> for a user not found
func TestHelloHandler_Get_UserNotFound(t *testing.T) {
	app, mock := setupTestApp(t)
	mock.ExpectQuery(`SELECT date_of_birth FROM users WHERE username = \$1`).
		WithArgs("unknownuser").
		WillReturnError(sql.ErrNoRows)

	req := httptest.NewRequest(http.MethodGet, "/hello/unknownuser", nil)
	w := httptest.NewRecorder()

	app.HelloHandler(w, req)
	res := w.Result()

	if res.StatusCode != http.StatusNotFound {
		t.Errorf("expected status 404 Not Found, got %d", res.StatusCode)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("unfulfilled expectations: %v", err)
	}
}

// Test GET user found with birthday NOT today (future birthday)
func TestHelloHandler_Get_BirthdayFuture(t *testing.T) {
	app, mock := setupTestApp(t)

	futureDate := time.Now().AddDate(0, 0, 10)

	mock.ExpectQuery(`SELECT date_of_birth FROM users WHERE username = \$1`).
		WithArgs("testuser").
		WillReturnRows(sqlmock.NewRows([]string{"date_of_birth"}).AddRow(futureDate))

	req := httptest.NewRequest(http.MethodGet, "/hello/testuser", nil)
	w := httptest.NewRecorder()

	app.HelloHandler(w, req)
	res := w.Result()

	if res.StatusCode != http.StatusOK {
		t.Errorf("expected status 200 OK, got %d", res.StatusCode)
	}

	body := w.Body.String()
	expected := fmt.Sprintf("Your birthday is in %d day(s)", 10)
	if !strings.Contains(body, expected) {
		t.Errorf("expected message to contain '%s', got %s", expected, body)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("unfulfilled expectations: %v", err)
	}
}

// Test PUT /hello/<username> with empty body (invalid JSON)
func TestHelloHandler_Put_EmptyBody(t *testing.T) {
	app, _ := setupTestApp(t)

	req := httptest.NewRequest(http.MethodPut, "/hello/testuser", nil)
	w := httptest.NewRecorder()

	app.HelloHandler(w, req)
	res := w.Result()

	if res.StatusCode != http.StatusBadRequest {
		t.Errorf("expected status 400 Bad Request for empty body, got %d", res.StatusCode)
	}
}

// Test GET with invalid username format (contains digits or symbols)
func TestHelloHandler_Get_InvalidUsername(t *testing.T) {
	app, _ := setupTestApp(t)

	req := httptest.NewRequest(http.MethodGet, "/hello/user123!", nil)
	w := httptest.NewRecorder()

	app.HelloHandler(w, req)
	res := w.Result()

	if res.StatusCode != http.StatusBadRequest {
		t.Errorf("expected status 400 Bad Request for invalid username, got %d", res.StatusCode)
	}
}
