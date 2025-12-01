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

// TestCassandraReadModels tests the read models functionality in Cassandra
func TestCassandraReadModels(t *testing.T) {
	// Skip if running in short mode
	if testing.Short() {
		t.Skip("Skipping Cassandra test in short mode")
	}

	// Setup test environment
	ctx := context.Background()
	userServiceURL := "http://localhost:8081"
	diaryServiceURL := "http://localhost:8082"

	// Connect to Cassandra
	cluster := gocql.NewCluster("localhost")
	cluster.Keyspace = "metachat"
	cluster.Consistency = gocql.Quorum
	session, err := cluster.CreateSession()
	require.NoError(t, err)
	defer session.Close()

	// Create a new user
	userID := createUser(t, ctx, userServiceURL)

	// Wait for the user read model to be updated
	time.Sleep(2 * time.Second)

	// Verify the user read model in Cassandra
	verifyUserReadModel(t, session, userID)

	// Update the user profile
	updateUserProfile(t, ctx, userServiceURL, userID)

	// Wait for the user read model to be updated
	time.Sleep(2 * time.Second)

	// Verify the updated user read model in Cassandra
	verifyUpdatedUserReadModel(t, session, userID)

	// Assign an archetype to the user
	assignArchetype(t, ctx, userServiceURL, userID)

	// Wait for the user archetype read model to be updated
	time.Sleep(2 * time.Second)

	// Verify the user archetype read model in Cassandra
	verifyUserArchetypeReadModel(t, session, userID)

	// Create a diary entry for the user
	diaryEntryID := createDiaryEntry(t, ctx, diaryServiceURL, userID)

	// Wait for the diary entry read model to be updated
	time.Sleep(2 * time.Second)

	// Verify the diary entry read model in Cassandra
	verifyDiaryEntryReadModel(t, session, diaryEntryID)

	// Update the diary entry
	updateDiaryEntry(t, ctx, diaryServiceURL, diaryEntryID)

	// Wait for the diary entry read model to be updated
	time.Sleep(2 * time.Second)

	// Verify the updated diary entry read model in Cassandra
	verifyUpdatedDiaryEntryReadModel(t, session, diaryEntryID)

	// Delete the diary entry
	deleteDiaryEntry(t, ctx, diaryServiceURL, diaryEntryID)

	// Wait for the diary entry read model to be updated
	time.Sleep(2 * time.Second)

	// Verify the diary entry read model was deleted
	verifyDiaryEntryReadModelDeleted(t, session, diaryEntryID)
}

// verifyUserReadModel verifies the user read model in Cassandra
func verifyUserReadModel(t *testing.T, session *gocql.Session, userID string) {
	t.Helper()

	var userReadModel struct {
		ID          string    `cql:"id"`
		Username    string    `cql:"username"`
		Email       string    `cql:"email"`
		FirstName   string    `cql:"first_name"`
		LastName    string    `cql:"last_name"`
		DateOfBirth string    `cql:"date_of_birth"`
		Avatar      string    `cql:"avatar"`
		Bio         string    `cql:"bio"`
		CreatedAt   time.Time `cql:"created_at"`
		UpdatedAt   time.Time `cql:"updated_at"`
	}

	err := session.Query(
		"SELECT id, username, email, first_name, last_name, date_of_birth, avatar, bio, created_at, updated_at FROM user_read_models WHERE id = ?",
		userID,
	).Consistency(gocql.One).Scan(
		&userReadModel.ID,
		&userReadModel.Username,
		&userReadModel.Email,
		&userReadModel.FirstName,
		&userReadModel.LastName,
		&userReadModel.DateOfBirth,
		&userReadModel.Avatar,
		&userReadModel.Bio,
		&userReadModel.CreatedAt,
		&userReadModel.UpdatedAt,
	)
	require.NoError(t, err)

	assert.Equal(t, userID, userReadModel.ID)
	assert.Equal(t, "Test", userReadModel.FirstName)
	assert.Equal(t, "User", userReadModel.LastName)
	assert.False(t, userReadModel.CreatedAt.IsZero())
}

// verifyUpdatedUserReadModel verifies the updated user read model in Cassandra
func verifyUpdatedUserReadModel(t *testing.T, session *gocql.Session, userID string) {
	t.Helper()

	var userReadModel struct {
		ID          string    `cql:"id"`
		Username    string    `cql:"username"`
		Email       string    `cql:"email"`
		FirstName   string    `cql:"first_name"`
		LastName    string    `cql:"last_name"`
		DateOfBirth string    `cql:"date_of_birth"`
		Avatar      string    `cql:"avatar"`
		Bio         string    `cql:"bio"`
		CreatedAt   time.Time `cql:"created_at"`
		UpdatedAt   time.Time `cql:"updated_at"`
	}

	err := session.Query(
		"SELECT id, username, email, first_name, last_name, date_of_birth, avatar, bio, created_at, updated_at FROM user_read_models WHERE id = ?",
		userID,
	).Consistency(gocql.One).Scan(
		&userReadModel.ID,
		&userReadModel.Username,
		&userReadModel.Email,
		&userReadModel.FirstName,
		&userReadModel.LastName,
		&userReadModel.DateOfBirth,
		&userReadModel.Avatar,
		&userReadModel.Bio,
		&userReadModel.CreatedAt,
		&userReadModel.UpdatedAt,
	)
	require.NoError(t, err)

	assert.Equal(t, userID, userReadModel.ID)
	assert.Equal(t, "Updated", userReadModel.FirstName)
	assert.Equal(t, "User", userReadModel.LastName)
	assert.Equal(t, "Updated bio for integration testing", userReadModel.Bio)
	assert.True(t, userReadModel.UpdatedAt.After(userReadModel.CreatedAt))
}

// verifyUserArchetypeReadModel verifies the user archetype read model in Cassandra
func verifyUserArchetypeReadModel(t *testing.T, session *gocql.Session, userID string) {
	t.Helper()

	var userArchetypeReadModel struct {
		UserID        string    `cql:"user_id"`
		ArchetypeID   string    `cql:"archetype_id"`
		ArchetypeName string    `cql:"archetype_name"`
		Confidence    float64   `cql:"confidence"`
		Description   string    `cql:"description"`
		CreatedAt     time.Time `cql:"created_at"`
		UpdatedAt     time.Time `cql:"updated_at"`
	}

	err := session.Query(
		"SELECT user_id, archetype_id, archetype_name, confidence, description, created_at, updated_at FROM user_archetype_read_models WHERE user_id = ?",
		userID,
	).Consistency(gocql.One).Scan(
		&userArchetypeReadModel.UserID,
		&userArchetypeReadModel.ArchetypeID,
		&userArchetypeReadModel.ArchetypeName,
		&userArchetypeReadModel.Confidence,
		&userArchetypeReadModel.Description,
		&userArchetypeReadModel.CreatedAt,
		&userArchetypeReadModel.UpdatedAt,
	)
	require.NoError(t, err)

	assert.Equal(t, userID, userArchetypeReadModel.UserID)
	assert.Equal(t, "thinker", userArchetypeReadModel.ArchetypeID)
	assert.Equal(t, "The Thinker", userArchetypeReadModel.ArchetypeName)
	assert.Equal(t, 0.85, userArchetypeReadModel.Confidence)
	assert.Equal(t, "Analytical and introspective personality type", userArchetypeReadModel.Description)
	assert.False(t, userArchetypeReadModel.CreatedAt.IsZero())
}

// verifyDiaryEntryReadModel verifies the diary entry read model in Cassandra
func verifyDiaryEntryReadModel(t *testing.T, session *gocql.Session, diaryEntryID string) {
	t.Helper()

	var diaryEntryReadModel struct {
		ID         string    `cql:"id"`
		UserID     string    `cql:"user_id"`
		Title      string    `cql:"title"`
		Content    string    `cql:"content"`
		TokenCount int       `cql:"token_count"`
		SessionID  string    `cql:"session_id"`
		Tags       []string  `cql:"tags"`
		CreatedAt  time.Time `cql:"created_at"`
		UpdatedAt  time.Time `cql:"updated_at"`
	}

	err := session.Query(
		"SELECT id, user_id, title, content, token_count, session_id, tags, created_at, updated_at FROM diary_entry_read_models WHERE id = ?",
		diaryEntryID,
	).Consistency(gocql.One).Scan(
		&diaryEntryReadModel.ID,
		&diaryEntryReadModel.UserID,
		&diaryEntryReadModel.Title,
		&diaryEntryReadModel.Content,
		&diaryEntryReadModel.TokenCount,
		&diaryEntryReadModel.SessionID,
		&diaryEntryReadModel.Tags,
		&diaryEntryReadModel.CreatedAt,
		&diaryEntryReadModel.UpdatedAt,
	)
	require.NoError(t, err)

	assert.Equal(t, diaryEntryID, diaryEntryReadModel.ID)
	assert.Equal(t, "Test Diary Entry", diaryEntryReadModel.Title)
	assert.Contains(t, diaryEntryReadModel.Content, "test diary entry")
	assert.Equal(t, 15, diaryEntryReadModel.TokenCount)
	assert.Contains(t, diaryEntryReadModel.Tags, "test")
	assert.Contains(t, diaryEntryReadModel.Tags, "integration")
	assert.False(t, diaryEntryReadModel.CreatedAt.IsZero())
}

// verifyUpdatedDiaryEntryReadModel verifies the updated diary entry read model in Cassandra
func verifyUpdatedDiaryEntryReadModel(t *testing.T, session *gocql.Session, diaryEntryID string) {
	t.Helper()

	var diaryEntryReadModel struct {
		ID         string    `cql:"id"`
		UserID     string    `cql:"user_id"`
		Title      string    `cql:"title"`
		Content    string    `cql:"content"`
		TokenCount int       `cql:"token_count"`
		SessionID  string    `cql:"session_id"`
		Tags       []string  `cql:"tags"`
		CreatedAt  time.Time `cql:"created_at"`
		UpdatedAt  time.Time `cql:"updated_at"`
	}

	err := session.Query(
		"SELECT id, user_id, title, content, token_count, session_id, tags, created_at, updated_at FROM diary_entry_read_models WHERE id = ?",
		diaryEntryID,
	).Consistency(gocql.One).Scan(
		&diaryEntryReadModel.ID,
		&diaryEntryReadModel.UserID,
		&diaryEntryReadModel.Title,
		&diaryEntryReadModel.Content,
		&diaryEntryReadModel.TokenCount,
		&diaryEntryReadModel.SessionID,
		&diaryEntryReadModel.Tags,
		&diaryEntryReadModel.CreatedAt,
		&diaryEntryReadModel.UpdatedAt,
	)
	require.NoError(t, err)

	assert.Equal(t, diaryEntryID, diaryEntryReadModel.ID)
	assert.Equal(t, "Updated Test Diary Entry", diaryEntryReadModel.Title)
	assert.Contains(t, diaryEntryReadModel.Content, "updated test diary entry")
	assert.Equal(t, 20, diaryEntryReadModel.TokenCount)
	assert.Contains(t, diaryEntryReadModel.Tags, "test")
	assert.Contains(t, diaryEntryReadModel.Tags, "integration")
	assert.Contains(t, diaryEntryReadModel.Tags, "updated")
	assert.True(t, diaryEntryReadModel.UpdatedAt.After(diaryEntryReadModel.CreatedAt))
}

// verifyDiaryEntryReadModelDeleted verifies that the diary entry read model was deleted
func verifyDiaryEntryReadModelDeleted(t *testing.T, session *gocql.Session, diaryEntryID string) {
	t.Helper()

	var id string
	err := session.Query(
		"SELECT id FROM diary_entry_read_models WHERE id = ?",
		diaryEntryID,
	).Consistency(gocql.One).Scan(&id)
	assert.Error(t, err)
	assert.Equal(t, gocql.ErrNotFound, err)
}

// TestCassandraSessionReadModels tests the diary session read models in Cassandra
func TestCassandraSessionReadModels(t *testing.T) {
	// Skip if running in short mode
	if testing.Short() {
		t.Skip("Skipping Cassandra test in short mode")
	}

	// Setup test environment
	ctx := context.Background()
	userServiceURL := "http://localhost:8081"
	diaryServiceURL := "http://localhost:8082"

	// Connect to Cassandra
	cluster := gocql.NewCluster("localhost")
	cluster.Keyspace = "metachat"
	cluster.Consistency = gocql.Quorum
	session, err := cluster.CreateSession()
	require.NoError(t, err)
	defer session.Close()

	// Create a new user
	userID := createUser(t, ctx, userServiceURL)

	// Create a diary entry for the user with a session ID
	sessionID := fmt.Sprintf("test-session-%d", time.Now().Unix())
	diaryEntryID := createDiaryEntryWithSession(t, ctx, diaryServiceURL, userID, sessionID)

	// Wait for the diary entry read model to be updated
	time.Sleep(2 * time.Second)

	// Verify the diary entry read model in Cassandra
	verifyDiaryEntryReadModel(t, session, diaryEntryID)

	// Verify the diary session read model in Cassandra
	verifyDiarySessionReadModel(t, session, userID, sessionID)
}

// createDiaryEntryWithSession creates a diary entry with a specific session ID
func createDiaryEntryWithSession(t *testing.T, ctx context.Context, baseURL, userID, sessionID string) string {
	t.Helper()

	diaryEntry := map[string]interface{}{
		"userId":     userID,
		"title":      "Test Diary Entry",
		"content":    "This is a test diary entry for integration testing.",
		"tokenCount": 15,
		"sessionId":  sessionID,
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

// verifyDiarySessionReadModel verifies the diary session read model in Cassandra
func verifyDiarySessionReadModel(t *testing.T, session *gocql.Session, userID, sessionID string) {
	t.Helper()

	var diarySessionReadModel struct {
		ID         string     `cql:"id"`
		UserID     string     `cql:"user_id"`
		StartedAt  time.Time  `cql:"started_at"`
		EndedAt    *time.Time `cql:"ended_at"`
		EntryCount int        `cql:"entry_count"`
		CreatedAt  time.Time  `cql:"created_at"`
		UpdatedAt  time.Time  `cql:"updated_at"`
	}

	err := session.Query(
		"SELECT id, user_id, started_at, ended_at, entry_count, created_at, updated_at FROM diary_session_read_models WHERE id = ?",
		sessionID,
	).Consistency(gocql.One).Scan(
		&diarySessionReadModel.ID,
		&diarySessionReadModel.UserID,
		&diarySessionReadModel.StartedAt,
		&diarySessionReadModel.EndedAt,
		&diarySessionReadModel.EntryCount,
		&diarySessionReadModel.CreatedAt,
		&diarySessionReadModel.UpdatedAt,
	)
	require.NoError(t, err)

	assert.Equal(t, sessionID, diarySessionReadModel.ID)
	assert.Equal(t, userID, diarySessionReadModel.UserID)
	assert.False(t, diarySessionReadModel.StartedAt.IsZero())
	assert.Nil(t, diarySessionReadModel.EndedAt) // Session is still active
	assert.Equal(t, 1, diarySessionReadModel.EntryCount)
	assert.False(t, diarySessionReadModel.CreatedAt.IsZero())
}
