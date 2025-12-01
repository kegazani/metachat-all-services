package tests

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"testing"
	"time"

	"github.com/gocql/gocql"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// verifyUser checks if a user exists in the read model
func verifyUser(t *testing.T, ctx context.Context, userServiceURL, userID string) {
	t.Helper()

	req, err := http.NewRequestWithContext(ctx, "GET", userServiceURL+"/users/"+userID, nil)
	if err != nil {
		t.Fatalf("Failed to create request: %v", err)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("Failed to get user: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("Expected status 200, got %d", resp.StatusCode)
	}

	var user map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&user); err != nil {
		t.Fatalf("Failed to decode user response: %v", err)
	}

	if user["id"] != userID {
		t.Fatalf("Expected user ID %s, got %v", userID, user["id"])
	}
}

// verifyDiaryEntry checks if a diary entry exists in the read model
func verifyDiaryEntry(t *testing.T, ctx context.Context, diaryServiceURL, entryID string) {
	t.Helper()

	req, err := http.NewRequestWithContext(ctx, "GET", diaryServiceURL+"/diary/entries/"+entryID, nil)
	if err != nil {
		t.Fatalf("Failed to create request: %v", err)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("Failed to get diary entry: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("Expected status 200, got %d", resp.StatusCode)
	}

	var entry map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&entry); err != nil {
		t.Fatalf("Failed to decode diary entry response: %v", err)
	}

	if entry["id"] != entryID {
		t.Fatalf("Expected entry ID %s, got %v", entryID, entry["id"])
	}
}

// verifyUserReadModel checks if a user exists in the Cassandra read model
func verifyUserReadModel(t *testing.T, session *gocql.Session, userID string) {
	t.Helper()

	var id, username, email string
	err := session.Query(`
		SELECT id, username, email FROM user_read_model WHERE id = ? LIMIT 1
	`, userID).Consistency(gocql.One).Scan(&id, &username, &email)

	if err != nil {
		t.Fatalf("Failed to query user read model: %v", err)
	}

	assert.Equal(t, userID, id)
	assert.NotEmpty(t, username)
	assert.NotEmpty(t, email)
}

// verifyUserArchetypeReadModel checks if a user archetype exists in the Cassandra read model
func verifyUserArchetypeReadModel(t *testing.T, session *gocql.Session, userID string) {
	t.Helper()

	var id, archetype string
	err := session.Query(`
		SELECT id, archetype FROM user_archetype_read_model WHERE id = ? LIMIT 1
	`, userID).Consistency(gocql.One).Scan(&id, &archetype)

	if err != nil {
		t.Fatalf("Failed to query user archetype read model: %v", err)
	}

	assert.Equal(t, userID, id)
	assert.NotEmpty(t, archetype)
}

// verifyDiaryEntryReadModel checks if a diary entry exists in the Cassandra read model
func verifyDiaryEntryReadModel(t *testing.T, session *gocql.Session, entryID string) {
	t.Helper()

	var id, userID, title string
	err := session.Query(`
		SELECT id, user_id, title FROM diary_entry_read_model WHERE id = ? LIMIT 1
	`, entryID).Consistency(gocql.One).Scan(&id, &userID, &title)

	if err != nil {
		t.Fatalf("Failed to query diary entry read model: %v", err)
	}

	assert.Equal(t, entryID, id)
	assert.NotEmpty(t, userID)
	assert.NotEmpty(t, title)
}

// verifyDiarySessionReadModel checks if a diary session exists in the Cassandra read model
func verifyDiarySessionReadModel(t *testing.T, session *gocql.Session, userID, sessionID string) {
	t.Helper()

	var id, title string
	err := session.Query(`
		SELECT id, title FROM diary_session_read_model WHERE id = ? AND user_id = ? LIMIT 1
	`, sessionID, userID).Consistency(gocql.One).Scan(&id, &title)

	if err != nil {
		t.Fatalf("Failed to query diary session read model: %v", err)
	}

	assert.Equal(t, sessionID, id)
	assert.NotEmpty(t, title)
}

// verifyDiaryEntryDeleted checks if a diary entry was deleted
func verifyDiaryEntryDeleted(t *testing.T, ctx context.Context, diaryServiceURL, entryID string) {
	t.Helper()

	req, err := http.NewRequestWithContext(ctx, "GET", diaryServiceURL+"/diary/entries/"+entryID, nil)
	if err != nil {
		t.Fatalf("Failed to create request: %v", err)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("Failed to get diary entry: %v", err)
	}
	defer resp.Body.Close()

	assert.Equal(t, http.StatusNotFound, resp.StatusCode)
}

// verifyDiaryEntryReadModelDeleted checks if a diary entry was deleted from the read model
func verifyDiaryEntryReadModelDeleted(t *testing.T, session *gocql.Session, entryID string) {
	t.Helper()

	var id string
	err := session.Query(`
		SELECT id FROM diary_entry_read_model WHERE id = ? LIMIT 1
	`, entryID).Consistency(gocql.One).Scan(&id)

	assert.Equal(t, gocql.ErrNotFound, err)
}

// createUser creates a user via the User Service API
func createUser(t *testing.T, ctx context.Context, baseURL string) string {
	t.Helper()

	user := map[string]interface{}{
		"username":    "testuser_" + time.Now().Format("20060102150405"),
		"email":       "testuser_" + time.Now().Format("20060102150405") + "@example.com",
		"firstName":   "Test",
		"lastName":    "User",
		"dateOfBirth": "1990-01-01",
	}

	jsonData, err := json.Marshal(user)
	require.NoError(t, err)

	req, err := http.NewRequestWithContext(ctx, "POST", baseURL+"/users", bytes.NewBuffer(jsonData))
	require.NoError(t, err)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusCreated, resp.StatusCode)

	var response map[string]interface{}
	err = json.NewDecoder(resp.Body).Decode(&response)
	require.NoError(t, err)

	userID, ok := response["id"].(string)
	require.True(t, ok, "Response should contain user ID")

	return userID
}

// updateUserProfile updates a user profile via the User Service API
func updateUserProfile(t *testing.T, ctx context.Context, baseURL, userID string) {
	t.Helper()

	profile := map[string]interface{}{
		"firstName": "Updated",
		"lastName":  "User",
		"bio":       "Updated bio for testing",
	}

	jsonData, err := json.Marshal(profile)
	require.NoError(t, err)

	req, err := http.NewRequestWithContext(ctx, "PUT", baseURL+"/users/"+userID+"/profile", bytes.NewBuffer(jsonData))
	require.NoError(t, err)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusOK, resp.StatusCode)
}

// assignArchetype assigns an archetype to a user via the User Service API
func assignArchetype(t *testing.T, ctx context.Context, baseURL, userID string) {
	t.Helper()

	archetype := map[string]interface{}{
		"archetype": "Explorer",
	}

	jsonData, err := json.Marshal(archetype)
	require.NoError(t, err)

	req, err := http.NewRequestWithContext(ctx, "PUT", baseURL+"/users/"+userID+"/archetype", bytes.NewBuffer(jsonData))
	require.NoError(t, err)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusOK, resp.StatusCode)
}

// createDiaryEntryWithSession creates a diary entry with a session via the Diary Service API
func createDiaryEntryWithSession(t *testing.T, ctx context.Context, baseURL, userID, sessionID string) string {
	t.Helper()

	entry := map[string]interface{}{
		"userId":    userID,
		"title":     "Test Entry",
		"content":   "This is a test diary entry.",
		"sessionId": sessionID,
	}

	jsonData, err := json.Marshal(entry)
	require.NoError(t, err)

	req, err := http.NewRequestWithContext(ctx, "POST", baseURL+"/diary/entries", bytes.NewBuffer(jsonData))
	require.NoError(t, err)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusCreated, resp.StatusCode)

	var response map[string]interface{}
	err = json.NewDecoder(resp.Body).Decode(&response)
	require.NoError(t, err)

	entryID, ok := response["id"].(string)
	require.True(t, ok, "Response should contain entry ID")

	return entryID
}

// createDiaryEntry creates a diary entry without a session via the Diary Service API
func createDiaryEntry(t *testing.T, ctx context.Context, baseURL, userID string) string {
	t.Helper()

	entry := map[string]interface{}{
		"userId":     userID,
		"title":      "Test Diary Entry",
		"content":    "This is a test diary entry for integration testing.",
		"tokenCount": 15,
		"sessionId":  fmt.Sprintf("session_%d", time.Now().Unix()),
		"tags":       []string{"test", "integration"},
	}

	jsonData, err := json.Marshal(entry)
	require.NoError(t, err)

	req, err := http.NewRequestWithContext(ctx, "POST", baseURL+"/diary/entries", bytes.NewBuffer(jsonData))
	require.NoError(t, err)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusCreated, resp.StatusCode)

	var response map[string]interface{}
	err = json.NewDecoder(resp.Body).Decode(&response)
	require.NoError(t, err)

	entryID, ok := response["id"].(string)
	require.True(t, ok, "Response should contain entry ID")

	return entryID
}

// getUser retrieves a user via the User Service API
func getUser(t *testing.T, ctx context.Context, baseURL, userID string) {
	t.Helper()

	req, err := http.NewRequestWithContext(ctx, "GET", baseURL+"/users/"+userID, nil)
	require.NoError(t, err)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusOK, resp.StatusCode)

	var user map[string]interface{}
	err = json.NewDecoder(resp.Body).Decode(&user)
	require.NoError(t, err)

	assert.Equal(t, userID, user["id"])
	assert.Equal(t, "Updated", user["firstName"])
	assert.Equal(t, "User", user["lastName"])
	assert.Equal(t, "Updated bio for testing", user["bio"])
}

// getDiaryEntry retrieves a diary entry via the Diary Service API
func getDiaryEntry(t *testing.T, ctx context.Context, baseURL, diaryEntryID string) {
	t.Helper()

	req, err := http.NewRequestWithContext(ctx, "GET", baseURL+"/diary/entries/"+diaryEntryID, nil)
	require.NoError(t, err)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusOK, resp.StatusCode)

	var diaryEntry map[string]interface{}
	err = json.NewDecoder(resp.Body).Decode(&diaryEntry)
	require.NoError(t, err)

	assert.Equal(t, diaryEntryID, diaryEntry["id"])
	assert.Equal(t, "Updated Test Entry", diaryEntry["title"])
	assert.Contains(t, diaryEntry["content"], "updated test diary entry")
}

// getUserWithArchetype retrieves a user with archetype information via the User Service API
func getUserWithArchetype(t *testing.T, ctx context.Context, baseURL, userID string) {
	t.Helper()

	req, err := http.NewRequestWithContext(ctx, "GET", baseURL+"/users/"+userID, nil)
	require.NoError(t, err)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusOK, resp.StatusCode)

	var user map[string]interface{}
	err = json.NewDecoder(resp.Body).Decode(&user)
	require.NoError(t, err)

	assert.Equal(t, userID, user["id"])

	// Check if archetype is present
	archetype, ok := user["archetype"].(map[string]interface{})
	require.True(t, ok, "User should have archetype information")

	assert.Equal(t, "thinker", archetype["id"])
	assert.Equal(t, "The Thinker", archetype["name"])
	assert.Equal(t, 0.85, archetype["confidence"])
	assert.Equal(t, "Analytical and introspective personality type", archetype["description"])
}

// updateDiaryEntry updates a diary entry via the Diary Service API
func updateDiaryEntry(t *testing.T, ctx context.Context, baseURL, entryID string) {
	t.Helper()

	entry := map[string]interface{}{
		"title":   "Updated Test Entry",
		"content": "This is an updated test diary entry.",
	}

	jsonData, err := json.Marshal(entry)
	require.NoError(t, err)

	req, err := http.NewRequestWithContext(ctx, "PUT", baseURL+"/diary/entries/"+entryID, bytes.NewBuffer(jsonData))
	require.NoError(t, err)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusOK, resp.StatusCode)
}

// deleteDiaryEntry deletes a diary entry via the Diary Service API
func deleteDiaryEntry(t *testing.T, ctx context.Context, baseURL, entryID string) {
	t.Helper()

	req, err := http.NewRequestWithContext(ctx, "DELETE", baseURL+"/diary/entries/"+entryID, nil)
	require.NoError(t, err)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusOK, resp.StatusCode)
}
