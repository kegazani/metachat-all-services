package kafka

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"metachat/user-service/internal/repository"

	"github.com/kegazani/metachat-event-sourcing/events"
	"github.com/IBM/sarama"
	"github.com/sirupsen/logrus"
)

type PersonalityEventConsumer interface {
	Start(ctx context.Context) error
	Stop() error
}

type personalityEventConsumer struct {
	consumerGroup     sarama.ConsumerGroup
	userReadRepo      repository.UserReadRepository
	topics            []string
	logger            *logrus.Logger
}

func NewPersonalityEventConsumer(
	bootstrapServers string,
	consumerGroupID string,
	topics []string,
	userReadRepo repository.UserReadRepository,
	logger *logrus.Logger,
) (PersonalityEventConsumer, error) {
	config := sarama.NewConfig()
	config.Consumer.Group.Rebalance.Strategy = sarama.NewBalanceStrategyRoundRobin()
	config.Consumer.Offsets.Initial = sarama.OffsetOldest
	config.Consumer.Return.Errors = true
	config.Version = sarama.V2_8_0_0

	brokers := strings.Split(bootstrapServers, ",")
	for i := range brokers {
		brokers[i] = strings.TrimSpace(brokers[i])
	}

	consumerGroup, err := sarama.NewConsumerGroup(brokers, consumerGroupID, config)
	if err != nil {
		return nil, fmt.Errorf("failed to create consumer group: %w", err)
	}

	return &personalityEventConsumer{
		consumerGroup: consumerGroup,
		userReadRepo:  userReadRepo,
		topics:        topics,
		logger:        logger,
	}, nil
}

func (c *personalityEventConsumer) Start(ctx context.Context) error {
	handler := &personalityConsumerGroupHandler{
		userReadRepo: c.userReadRepo,
		logger:       c.logger,
	}

	go func() {
		for {
			if err := c.consumerGroup.Consume(ctx, c.topics, handler); err != nil {
				c.logger.WithError(err).Error("Error from consumer")
				return
			}
			if ctx.Err() != nil {
				return
			}
		}
	}()

	go func() {
		for err := range c.consumerGroup.Errors() {
			c.logger.WithError(err).Error("Consumer group error")
		}
	}()

	c.logger.WithFields(logrus.Fields{
		"topics": c.topics,
		"group":  c.consumerGroup,
	}).Info("Personality event consumer started")

	return nil
}

func (c *personalityEventConsumer) Stop() error {
	return c.consumerGroup.Close()
}

type personalityConsumerGroupHandler struct {
	userReadRepo repository.UserReadRepository
	logger       *logrus.Logger
}

func (h *personalityConsumerGroupHandler) Setup(sarama.ConsumerGroupSession) error {
	return nil
}

func (h *personalityConsumerGroupHandler) Cleanup(sarama.ConsumerGroupSession) error {
	return nil
}

func (h *personalityConsumerGroupHandler) ConsumeClaim(session sarama.ConsumerGroupSession, claim sarama.ConsumerGroupClaim) error {
	for {
		select {
		case <-session.Context().Done():
			return nil
		case message := <-claim.Messages():
			if err := h.processMessage(session.Context(), message); err != nil {
				h.logger.WithError(err).WithFields(logrus.Fields{
					"topic":     message.Topic,
					"partition": message.Partition,
					"offset":    message.Offset,
				}).Error("Failed to process personality event")
				continue
			}
			session.MarkMessage(message, "")
		}
	}
}

func (h *personalityConsumerGroupHandler) processMessage(ctx context.Context, message *sarama.ConsumerMessage) error {
	var eventData map[string]interface{}
	if err := json.Unmarshal(message.Value, &eventData); err != nil {
		return fmt.Errorf("failed to unmarshal message: %w", err)
	}

	eventType, ok := eventData["event_type"].(string)
	if !ok {
		return fmt.Errorf("missing or invalid event_type")
	}

	if eventType == "PersonalityAssigned" || eventType == "PersonalityUpdated" {
		return h.processPersonalityEvent(ctx, eventData, eventType == "PersonalityAssigned")
	}

	return nil
}

func (h *personalityConsumerGroupHandler) processPersonalityEvent(ctx context.Context, eventData map[string]interface{}, isAssigned bool) error {
	payload, ok := eventData["payload"].(map[string]interface{})
	if !ok {
		if payloadStr, ok := eventData["payload"].(string); ok {
			if err := json.Unmarshal([]byte(payloadStr), &payload); err != nil {
				return fmt.Errorf("failed to unmarshal payload string: %w", err)
			}
		} else {
			return fmt.Errorf("missing or invalid payload")
		}
	}

	userID, ok := payload["user_id"].(string)
	if !ok {
		return fmt.Errorf("missing or invalid user_id in payload")
	}

	dominantTrait, _ := payload["dominant_trait"].(string)
	confidence, _ := payload["confidence"].(float64)

	var eventTimestamp time.Time
	if tsStr, ok := eventData["timestamp"].(string); ok {
		if parsed, err := time.Parse(time.RFC3339, tsStr); err == nil {
			eventTimestamp = parsed
		} else {
			eventTimestamp = time.Now()
		}
	} else {
		eventTimestamp = time.Now()
	}

	archetypeID, archetypeName, description := personalityToArchetype(dominantTrait)

	event := &events.Event{
		ID:          fmt.Sprintf("%v", eventData["event_id"]),
		Type:        events.UserArchetypeAssignedEvent,
		AggregateID: userID,
		Timestamp:   eventTimestamp,
		Version:     1,
	}

	if !isAssigned {
		event.Type = events.UserArchetypeUpdatedEvent
	}

	payloadData := events.UserArchetypeAssignedPayload{
		ArchetypeID:    archetypeID,
		ArchetypeName:  archetypeName,
		Confidence:     confidence,
		Description:    description,
	}

	payloadBytes, err := json.Marshal(payloadData)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %w", err)
	}

	event.Payload = payloadBytes

	if err := h.userReadRepo.ProcessUserEvent(ctx, event); err != nil {
		return fmt.Errorf("failed to process user event: %w", err)
	}

	h.logger.WithFields(logrus.Fields{
		"user_id":        userID,
		"archetype_id":   archetypeID,
		"archetype_name": archetypeName,
		"dominant_trait": dominantTrait,
		"confidence":     confidence,
	}).Info("Processed personality event and updated archetype")

	return nil
}

func personalityToArchetype(dominantTrait string) (archetypeID, archetypeName, description string) {
	traitMap := map[string]struct {
		ID          string
		Name        string
		Description string
	}{
		"openness": {
			ID:          "archetype-openness",
			Name:        "The Explorer",
			Description: "Creative, curious, and open to new experiences",
		},
		"conscientiousness": {
			ID:          "archetype-conscientiousness",
			Name:        "The Achiever",
			Description: "Organized, disciplined, and goal-oriented",
		},
		"extraversion": {
			ID:          "archetype-extraversion",
			Name:        "The Socializer",
			Description: "Outgoing, energetic, and enthusiastic",
		},
		"agreeableness": {
			ID:          "archetype-agreeableness",
			Name:        "The Helper",
			Description: "Compassionate, trusting, and cooperative",
		},
		"neuroticism": {
			ID:          "archetype-neuroticism",
			Name:        "The Sensitive",
			Description: "Emotionally aware, thoughtful, and introspective",
		},
	}

	if archetype, ok := traitMap[strings.ToLower(dominantTrait)]; ok {
		return archetype.ID, archetype.Name, archetype.Description
	}

	return "archetype-unknown", "The Seeker", "Exploring personality traits"
}

