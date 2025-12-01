package tests

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"testing"
	"time"

	"github.com/gocql/gocql"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestEndToEndUserJourney tests the complete user journey from registration to diary entry creation
func TestEndToEndUserJourney(t *testing.T) {
	// Skip if running in short mode
	if testing.Short() {
		t.Skip("Skipping end-to-end test in short mode")
	}

	// Setup test environment
	ctx := context.Background()
	userServiceURL := "http://localhost:8081"
	diaryServiceURL := "http://localhost:8082"

	// Connect to Cassandra
	cluster := gocql.NewCluster("localhost")
	cluster.Keyspace = "metachat"
	cluster.Consistency = gocql.Quorum
	cassandraSession, err := cluster.CreateSession()
	require.NoError(t, err)
	defer cassandraSession.Close()

	// Step 1: User Registration
	userID := createUser(t, ctx, userServiceURL)

	// Step 2: User Profile Update
	updateUserProfile(t, ctx, userServiceURL, userID)

	// Step 3: Archetype Assignment
	assignArchetype(t, ctx, userServiceURL, userID)

	// Step 4: Start a Diary Session
	sessionID := startDiarySession(t, ctx, diaryServiceURL, userID)

	// Step 5: Create Diary Entries
	entry1ID := createDiaryEntryWithSession(t, ctx, diaryServiceURL, userID, sessionID)
	entry2ID := createDiaryEntryWithSession(t, ctx, diaryServiceURL, userID, sessionID)

	// Step 6: Update Diary Entries
	updateDiaryEntry(t, ctx, diaryServiceURL, entry1ID)
	updateDiaryEntry(t, ctx, diaryServiceURL, entry2ID)

	// Step 7: End the Diary Session
	endDiarySession(t, ctx, diaryServiceURL, sessionID)

	// Step 8: Verify User Data
	verifyUser(t, ctx, userServiceURL, userID)

	// Step 9: Verify Diary Entries
	verifyDiaryEntry(t, ctx, diaryServiceURL, entry1ID)
	verifyDiaryEntry(t, ctx, diaryServiceURL, entry2ID)

	// Step 10: Verify Read Models in Cassandra
	verifyUserReadModel(t, cassandraSession, userID)
	verifyUserArchetypeReadModel(t, cassandraSession, userID)
	verifyDiaryEntryReadModel(t, cassandraSession, entry1ID)
	verifyDiaryEntryReadModel(t, cassandraSession, entry2ID)
	verifyDiarySessionReadModel(t, cassandraSession, userID, sessionID)

	// Step 11: Get User's Diary Entries
	userDiaryEntries := getUserDiaryEntries(t, ctx, diaryServiceURL, userID)
	assert.Len(t, userDiaryEntries, 2, "User should have 2 diary entries")

	// Step 12: Get User's Diary Sessions
	userDiarySessions := getUserDiarySessions(t, ctx, diaryServiceURL, userID)
	assert.Len(t, userDiarySessions, 1, "User should have 1 diary session")

	// Step 13: Delete Diary Entries
	deleteDiaryEntry(t, ctx, diaryServiceURL, entry1ID)
	deleteDiaryEntry(t, ctx, diaryServiceURL, entry2ID)

	// Step 14: Verify Diary Entries Were Deleted
	verifyDiaryEntryDeleted(t, ctx, diaryServiceURL, entry1ID)
	verifyDiaryEntryDeleted(t, ctx, diaryServiceURL, entry2ID)

	// Step 15: Verify Read Models Were Updated
	verifyDiaryEntryReadModelDeleted(t, cassandraSession, entry1ID)
	verifyDiaryEntryReadModelDeleted(t, cassandraSession, entry2ID)
}

// startDiarySession starts a diary session via the Diary Service API
func startDiarySession(t *testing.T, ctx context.Context, baseURL, userID string) string {
	t.Helper()

	session := map[string]interface{}{
		"userId": userID,
		"title":  "Test Session",
	}

	jsonData, err := json.Marshal(session)
	require.NoError(t, err)

	req, err := http.NewRequestWithContext(ctx, "POST", baseURL+"/diary/sessions", bytes.NewBuffer(jsonData))
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

	sessionID, ok := response["id"].(string)
	require.True(t, ok, "Response should contain session ID")

	return sessionID
}

// endDiarySession ends a diary session via the Diary Service API
func endDiarySession(t *testing.T, ctx context.Context, baseURL, sessionID string) {
	t.Helper()

	req, err := http.NewRequestWithContext(ctx, "PUT", baseURL+"/diary/sessions/"+sessionID+"/end", nil)
	require.NoError(t, err)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusOK, resp.StatusCode)
}

// getUserDiaryEntries retrieves a user's diary entries via the Diary Service API
func getUserDiaryEntries(t *testing.T, ctx context.Context, baseURL, userID string) []map[string]interface{} {
	t.Helper()

	req, err := http.NewRequestWithContext(ctx, "GET", baseURL+"/diary/entries/user/"+userID, nil)
	require.NoError(t, err)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusOK, resp.StatusCode)

	var response struct {
		Entries []map[string]interface{} `json:"entries"`
	}
	err = json.NewDecoder(resp.Body).Decode(&response)
	require.NoError(t, err)

	return response.Entries
}

// getUserDiarySessions retrieves a user's diary sessions via the Diary Service API
func getUserDiarySessions(t *testing.T, ctx context.Context, baseURL, userID string) []map[string]interface{} {
	t.Helper()

	req, err := http.NewRequestWithContext(ctx, "GET", baseURL+"/diary/sessions/user/"+userID, nil)
	require.NoError(t, err)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusOK, resp.StatusCode)

	var response struct {
		Sessions []map[string]interface{} `json:"sessions"`
	}
	err = json.NewDecoder(resp.Body).Decode(&response)
	require.NoError(t, err)

	return response.Sessions
}

// TestEndToEndAnalytics tests the analytics functionality
func TestEndToEndAnalytics(t *testing.T) {
	// Skip if running in short mode
	if testing.Short() {
		t.Skip("Skipping end-to-end test in short mode")
	}

	// Setup test environment
	ctx := context.Background()
	userServiceURL := "http://localhost:8081"
	diaryServiceURL := "http://localhost:8082"

	// Create multiple users
	var userIDs []string
	for i := 0; i < 5; i++ {
		userID := createUser(t, ctx, userServiceURL)
		userIDs = append(userIDs, userID)

		// Update user profile
		updateUserProfile(t, ctx, userServiceURL, userID)

		// Assign archetype
		assignArchetype(t, ctx, userServiceURL, userID)

		// Create diary sessions and entries
		for j := 0; j < 3; j++ {
			sessionID := startDiarySession(t, ctx, diaryServiceURL, userID)

			// Create multiple entries per session
			for k := 0; k < 2; k++ {
				createDiaryEntryWithSession(t, ctx, diaryServiceURL, userID, sessionID)
			}

			endDiarySession(t, ctx, diaryServiceURL, sessionID)
		}
	}

	// Wait for read models to be updated
	time.Sleep(5 * time.Second)

	// Verify analytics data
	verifyUserAnalytics(t, ctx, userServiceURL, diaryServiceURL)
	verifyDiaryAnalytics(t, ctx, diaryServiceURL)
}

// verifyUserAnalytics verifies user analytics data
func verifyUserAnalytics(t *testing.T, ctx context.Context, userServiceURL, diaryServiceURL string) {
	t.Helper()

	// Get all users
	req, err := http.NewRequestWithContext(ctx, "GET", userServiceURL+"/users", nil)
	require.NoError(t, err)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusOK, resp.StatusCode)

	var response struct {
		Users []map[string]interface{} `json:"users"`
	}
	err = json.NewDecoder(resp.Body).Decode(&response)
	require.NoError(t, err)

	// Verify we have at least 5 users
	assert.GreaterOrEqual(t, len(response.Users), 5)

	// Verify each user has archetype data
	for _, user := range response.Users {
		assert.NotEmpty(t, user["id"])
		assert.NotEmpty(t, user["username"])
		assert.NotEmpty(t, user["email"])
		assert.NotEmpty(t, user["firstName"])
		assert.NotEmpty(t, user["lastName"])
		assert.NotNil(t, user["archetype"])
	}
}

// verifyDiaryAnalytics verifies diary analytics data
func verifyDiaryAnalytics(t *testing.T, ctx context.Context, baseURL string) {
	t.Helper()

	// Get analytics data
	req, err := http.NewRequestWithContext(ctx, "GET", baseURL+"/diary/analytics", nil)
	require.NoError(t, err)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusOK, resp.StatusCode)

	var analytics map[string]interface{}
	err = json.NewDecoder(resp.Body).Decode(&analytics)
	require.NoError(t, err)

	// Verify analytics data
	assert.GreaterOrEqual(t, analytics["totalEntries"], 30.0)  // 5 users * 3 sessions * 2 entries
	assert.GreaterOrEqual(t, analytics["totalSessions"], 15.0) // 5 users * 3 sessions
	assert.GreaterOrEqual(t, analytics["activeUsers"], 5.0)
	assert.GreaterOrEqual(t, analytics["averageEntriesPerSession"], 2.0)
	assert.GreaterOrEqual(t, analytics["averageSessionsPerUser"], 3.0)
}
