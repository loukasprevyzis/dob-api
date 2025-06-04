package api

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"regexp"
	"strings"
	"time"
)

var validUsername = regexp.MustCompile(`^[A-Za-z]+$`)

type App struct {
	db *sql.DB
}

func NewApp(db *sql.DB) *App {
	return &App{db: db}
}

func (a *App) HelloHandler(w http.ResponseWriter, r *http.Request) {
	username := strings.TrimPrefix(r.URL.Path, "/hello/")
	if username == "" {
		http.Error(w, "Username missing", http.StatusBadRequest)
		return
	}
	if !validUsername.MatchString(username) {
		http.Error(w, "Invalid username format", http.StatusBadRequest)
		return
	}
	// username = strings.ToLower(username) // preserve original case for greeting and storage

	switch r.Method {
	case http.MethodPut:
		a.handlePut(w, r, username)
	case http.MethodGet:
		a.handleGet(w, username)
	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func (a *App) handlePut(w http.ResponseWriter, r *http.Request, username string) {
	var payload struct {
		DateOfBirth string `json:"dateOfBirth"`
	}
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	dob, err := time.Parse("2006-01-02", payload.DateOfBirth)
	if err != nil {
		http.Error(w, "Invalid date format, expected YYYY-MM-DD", http.StatusBadRequest)
		return
	}

	if !dob.Before(time.Now()) {
		http.Error(w, "Date of birth must be before today", http.StatusBadRequest)
		return
	}

	_, err = a.db.Exec(`
		INSERT INTO users (username, date_of_birth)
		VALUES ($1, $2)
		ON CONFLICT (username) DO UPDATE SET date_of_birth = EXCLUDED.date_of_birth`,
		username, dob,
	)
	if err != nil {
		http.Error(w, "Failed to save user", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (a *App) handleGet(w http.ResponseWriter, username string) {
	var dob time.Time
	err := a.db.QueryRow(`SELECT date_of_birth FROM users WHERE LOWER(username) = LOWER($1)`, username).Scan(&dob)
	if err == sql.ErrNoRows {
		http.Error(w, "User not found", http.StatusNotFound)
		return
	} else if err != nil {
		http.Error(w, "DB error", http.StatusInternalServerError)
		return
	}

	now := time.Now()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())

	nextBirthday := time.Date(now.Year(), dob.Month(), dob.Day(), 0, 0, 0, 0, now.Location())
	if nextBirthday.Before(today) {
		nextBirthday = nextBirthday.AddDate(1, 0, 0)
	}

	daysUntil := int(nextBirthday.Sub(today).Hours() / 24)

	var msg string
	if daysUntil == 0 {
		msg = fmt.Sprintf("Hello, %s! Happy birthday!", username)
	} else {
		msg = fmt.Sprintf("Hello, %s! Your birthday is in %d day(s)", username, daysUntil)
	}

	resp := map[string]string{"message": msg}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}
