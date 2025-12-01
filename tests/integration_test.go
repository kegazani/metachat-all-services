package tests

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestUserDiaryIntegration tests the integration between User Service and Diary Service
func TestUserDiaryIntegration(t *testing.T) {
	// Skip if running in short mode
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	// Setup test environment
	ctx := context.Background()
	userServiceURL := "http://localhost:8081"
	diaryServiceURL := "http://localhost:8082"

	// Create a new user
	userID := createUser(t, ctx, userServiceURL)

	// Create a diary entry for the user
	diaryEntryID := createDiaryEntry(t, ctx, diaryServiceURL, userID)

	// Update the user profile
	updateUserProfile(t, ctx, userServiceURL, userID)

	// Update the diary entry
	updateDiaryEntry(t, ctx, diaryServiceURL, diaryEntryID)

	// Get the user and verify the profile was updated
	getUser(t, ctx, userServiceURL, userID)

	// Get the diary entry and verify it was updated
	getDiaryEntry(t, ctx, diaryServiceURL, diaryEntryID)

	// Delete the diary entry
	deleteDiaryEntry(t, ctx, diaryServiceURL, diaryEntryID)

	// Verify the diary entry was deleted
	verifyDiaryEntryDeleted(t, ctx, diaryServiceURL, diaryEntryID)
}

// createDiaryEntry creates a new diary entry via the Diary Service API
func createDiaryEntry(t *testing.T, ctx context.Context, baseURL, userID string) string {
	t.Helper()

	diaryEntry := map[string]interface{}{
		"userId":     userID,
		"title":      "Test Diary Entry",
		"content":    "This is a test diary entry for integration testing.",
		"tokenCount": 15,
		"sessionId":  fmt.Sprintf("session_%d", time.Now().Unix()),
		"tags":       []string{"test", "integration"},
	}

	jsonData, err := json.Marshal(diaryEntry)
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

	diaryEntryID, ok := response["id"].(string)
	require.True(t, ok, "Response should contain diary entry ID")

	return diaryEntryID
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
	assert.Equal(t, "Updated bio for integration testing", user["bio"])
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
	assert.Equal(t, "Updated Test Diary Entry", diaryEntry["title"])
	assert.Contains(t, diaryEntry["content"], "updated test diary entry")
}

// TestUserArchetypeAssignment tests the archetype assignment functionality
func TestUserArchetypeAssignment(t *testing.T) {
	// Skip if running in short mode
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	// Setup test environment
	ctx := context.Background()
	userServiceURL := "http://localhost:8081"

	// Create a new user
	userID := createUser(t, ctx, userServiceURL)

	// Assign an archetype to the user
	assignArchetype(t, ctx, userServiceURL, userID)

	// Get the user and verify the archetype was assigned
	getUserWithArchetype(t, ctx, userServiceURL, userID)
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
