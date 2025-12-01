package tests

import (
	"context"
	"encoding/json"
	"fmt"
	"testing"
	"time"

	"github.com/confluentinc/confluent-kafka-go/kafka"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestKafkaEventPublishing tests that events are properly published to Kafka
func TestKafkaEventPublishing(t *testing.T) {
	// Skip if running in short mode
	if testing.Short() {
		t.Skip("Skipping Kafka test in short mode")
	}

	// Setup test environment
	ctx := context.Background()
	userServiceURL := "http://localhost:8081"
	diaryServiceURL := "http://localhost:8082"

	// Create Kafka consumer
	consumer, err := kafka.NewConsumer(&kafka.ConfigMap{
		"bootstrap.servers": "localhost:9092",
		"group.id":          fmt.Sprintf("test-consumer-%d", time.Now().Unix()),
		"auto.offset.reset": "earliest",
	})
	require.NoError(t, err)
	defer consumer.Close()

	// Subscribe to user events topic
	err = consumer.SubscribeTopics([]string{"user-events"}, nil)
	require.NoError(t, err)

	// Create a new user
	userID := createUser(t, ctx, userServiceURL)

	// Wait for and consume the UserCreated event
	event := consumeEvent(t, consumer, "UserCreated")
	assert.Equal(t, userID, event["userID"])

	// Update the user profile
	updateUserProfile(t, ctx, userServiceURL, userID)

	// Wait for and consume the UserProfileUpdated event
	event = consumeEvent(t, consumer, "UserProfileUpdated")
	assert.Equal(t, userID, event["userID"])

	// Assign an archetype to the user
	assignArchetype(t, ctx, userServiceURL, userID)

	// Wait for and consume the ArchetypeAssigned event
	event = consumeEvent(t, consumer, "ArchetypeAssigned")
	assert.Equal(t, userID, event["userID"])

	// Subscribe to diary events topic
	err = consumer.SubscribeTopics([]string{"diary-events"}, nil)
	require.NoError(t, err)

	// Create a diary entry for the user
	diaryEntryID := createDiaryEntry(t, ctx, diaryServiceURL, userID)

	// Wait for and consume the DiaryEntryCreated event
	event = consumeEvent(t, consumer, "DiaryEntryCreated")
	assert.Equal(t, userID, event["userID"])
	assert.Equal(t, diaryEntryID, event["diaryEntryID"])

	// Update the diary entry
	updateDiaryEntry(t, ctx, diaryServiceURL, diaryEntryID)

	// Wait for and consume the DiaryEntryUpdated event
	event = consumeEvent(t, consumer, "DiaryEntryUpdated")
	assert.Equal(t, diaryEntryID, event["diaryEntryID"])

	// Delete the diary entry
	deleteDiaryEntry(t, ctx, diaryServiceURL, diaryEntryID)

	// Wait for and consume the DiaryEntryDeleted event
	event = consumeEvent(t, consumer, "DiaryEntryDeleted")
	assert.Equal(t, diaryEntryID, event["diaryEntryID"])
}

// consumeEvent consumes a Kafka event of the expected type
func consumeEvent(t *testing.T, consumer *kafka.Consumer, expectedEventType string) map[string]interface{} {
	t.Helper()

	// Set a timeout for event consumption
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	for {
		select {
		case <-ctx.Done():
			t.Fatalf("Timeout waiting for %s event", expectedEventType)
		default:
			msg, err := consumer.ReadMessage(100 * time.Millisecond)
			if err != nil {
				if err.(kafka.Error).Code() == kafka.ErrTimedOut {
					continue
				}
				t.Fatalf("Failed to consume message: %v", err)
			}

			var event map[string]interface{}
			err = json.Unmarshal(msg.Value, &event)
			require.NoError(t, err)

			eventType, ok := event["eventType"].(string)
			require.True(t, ok, "Event should have eventType field")

			if eventType == expectedEventType {
				return event
			}
		}
	}
}

// TestKafkaEventConsumption tests that events are properly consumed from Kafka
func TestKafkaEventConsumption(t *testing.T) {
	// Skip if running in short mode
	if testing.Short() {
		t.Skip("Skipping Kafka test in short mode")
	}

	// Setup test environment
	ctx := context.Background()
	userServiceURL := "http://localhost:8081"
	diaryServiceURL := "http://localhost:8082"

	// Create Kafka producer
	producer, err := kafka.NewProducer(&kafka.ConfigMap{
		"bootstrap.servers": "localhost:9092",
	})
	require.NoError(t, err)
	defer producer.Flush(15 * 1000) // 15 seconds
	defer producer.Close()

	// Create a user event
	userEvent := map[string]interface{}{
		"eventType": "UserCreated",
		"timestamp": time.Now().UTC().Format(time.RFC3339),
		"userID":    fmt.Sprintf("test-user-%d", time.Now().Unix()),
		"username":  "testuser",
		"email":     "testuser@example.com",
		"firstName": "Test",
		"lastName":  "User",
	}

	// Publish the user event
	publishEvent(t, producer, "user-events", userEvent)

	// Wait for the event to be processed
	time.Sleep(5 * time.Second)

	// Verify the user was created
	userID := userEvent["userID"].(string)
	getUser(t, ctx, userServiceURL, userID)

	// Create a diary event
	diaryEvent := map[string]interface{}{
		"eventType":    "DiaryEntryCreated",
		"timestamp":    time.Now().UTC().Format(time.RFC3339),
		"diaryEntryID": fmt.Sprintf("test-diary-%d", time.Now().Unix()),
		"userID":       userID,
		"title":        "Test Diary Entry",
		"content":      "This is a test diary entry.",
		"tokenCount":   10,
		"sessionId":    fmt.Sprintf("test-session-%d", time.Now().Unix()),
		"tags":         []string{"test"},
	}

	// Publish the diary event
	publishEvent(t, producer, "diary-events", diaryEvent)

	// Wait for the event to be processed
	time.Sleep(5 * time.Second)

	// Verify the diary entry was created
	diaryEntryID := diaryEvent["diaryEntryID"].(string)
	getDiaryEntry(t, ctx, diaryServiceURL, diaryEntryID)
}

// publishEvent publishes an event to Kafka
func publishEvent(t *testing.T, producer *kafka.Producer, topic string, event map[string]interface{}) {
	t.Helper()

	jsonData, err := json.Marshal(event)
	require.NoError(t, err)

	msg := &kafka.Message{
		TopicPartition: kafka.TopicPartition{Topic: &topic, Partition: kafka.PartitionAny},
		Value:          jsonData,
	}

	deliveryChan := make(chan kafka.Event)
	err = producer.Produce(msg, deliveryChan)
	require.NoError(t, err)

	e := <-deliveryChan
	m := e.(*kafka.Message)

	if m.TopicPartition.Error != nil {
		t.Fatalf("Delivery failed: %v", m.TopicPartition.Error)
	}
}
