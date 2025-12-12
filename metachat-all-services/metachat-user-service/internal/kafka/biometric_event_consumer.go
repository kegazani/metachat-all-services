package kafka

import (
	"context"
	"encoding/json"
	"strings"
	"time"

	"github.com/IBM/sarama"
	"github.com/sirupsen/logrus"
)

type BiometricEventPayload struct {
	UserID               string   `json:"user_id"`
	HeartRate            *float64 `json:"heart_rate,omitempty"`
	HeartRateVariability *float64 `json:"heart_rate_variability,omitempty"`
	BloodOxygen          *float64 `json:"blood_oxygen,omitempty"`
	StressLevel          *int     `json:"stress_level,omitempty"`
	Steps                *int     `json:"steps,omitempty"`
	Calories             *float64 `json:"calories,omitempty"`
	SleepMinutes         *int     `json:"sleep_minutes,omitempty"`
	SleepScore           *int     `json:"sleep_score,omitempty"`
	HealthScore          *int     `json:"health_score,omitempty"`
	DeviceID             *string  `json:"device_id,omitempty"`
	DeviceType           *string  `json:"device_type,omitempty"`
	Timestamp            string   `json:"timestamp"`
}

type BiometricEvent struct {
	EventID       string                `json:"event_id"`
	EventType     string                `json:"event_type"`
	Timestamp     string                `json:"timestamp"`
	CorrelationID string                `json:"correlation_id"`
	Payload       BiometricEventPayload `json:"payload"`
}

type UserHealthUpdatedPayload struct {
	UserID                 string   `json:"user_id"`
	HealthScore            int      `json:"health_score"`
	TodaySteps             *int     `json:"today_steps,omitempty"`
	TodayCalories          *float64 `json:"today_calories,omitempty"`
	CurrentHeartRate       *float64 `json:"current_heart_rate,omitempty"`
	RestingHeartRate       *float64 `json:"resting_heart_rate,omitempty"`
	AvgHRV                 *float64 `json:"avg_hrv,omitempty"`
	AvgBloodOxygen         *float64 `json:"avg_blood_oxygen,omitempty"`
	AvgStressLevel         *float64 `json:"avg_stress_level,omitempty"`
	LastSleepScore         *int     `json:"last_sleep_score,omitempty"`
	LastSleepDurationHours *float64 `json:"last_sleep_duration_hours,omitempty"`
	Timestamp              string   `json:"timestamp"`
}

type UserHealthEvent struct {
	EventID       string                   `json:"event_id"`
	EventType     string                   `json:"event_type"`
	Timestamp     string                   `json:"timestamp"`
	CorrelationID string                   `json:"correlation_id"`
	Payload       UserHealthUpdatedPayload `json:"payload"`
}

type BiometricEventHandler interface {
	HandleWatchDataReceived(ctx context.Context, payload BiometricEventPayload) error
	HandleUserHealthUpdated(ctx context.Context, payload UserHealthUpdatedPayload) error
}

type BiometricEventConsumer struct {
	consumer sarama.ConsumerGroup
	topics   []string
	handler  BiometricEventHandler
	logger   *logrus.Logger
	ready    chan bool
	ctx      context.Context
	cancel   context.CancelFunc
}

func NewBiometricEventConsumer(
	bootstrapServers string,
	groupID string,
	topics []string,
	handler BiometricEventHandler,
	logger *logrus.Logger,
) (*BiometricEventConsumer, error) {
	config := sarama.NewConfig()
	config.Consumer.Group.Rebalance.GroupStrategies = []sarama.BalanceStrategy{sarama.NewBalanceStrategyRoundRobin()}
	config.Consumer.Offsets.Initial = sarama.OffsetNewest
	config.Consumer.Return.Errors = true

	brokers := strings.Split(bootstrapServers, ",")
	for i := range brokers {
		brokers[i] = strings.TrimSpace(brokers[i])
	}

	consumer, err := sarama.NewConsumerGroup(brokers, groupID, config)
	if err != nil {
		return nil, err
	}

	ctx, cancel := context.WithCancel(context.Background())

	return &BiometricEventConsumer{
		consumer: consumer,
		topics:   topics,
		handler:  handler,
		logger:   logger,
		ready:    make(chan bool),
		ctx:      ctx,
		cancel:   cancel,
	}, nil
}

func (c *BiometricEventConsumer) Start() {
	go func() {
		for {
			if err := c.consumer.Consume(c.ctx, c.topics, c); err != nil {
				c.logger.WithError(err).Error("Error from consumer")
			}
			if c.ctx.Err() != nil {
				return
			}
			c.ready = make(chan bool)
		}
	}()

	<-c.ready
	c.logger.Info("Biometric event consumer started")
}

func (c *BiometricEventConsumer) Stop() error {
	c.cancel()
	return c.consumer.Close()
}

func (c *BiometricEventConsumer) Setup(sarama.ConsumerGroupSession) error {
	close(c.ready)
	return nil
}

func (c *BiometricEventConsumer) Cleanup(sarama.ConsumerGroupSession) error {
	return nil
}

func (c *BiometricEventConsumer) ConsumeClaim(session sarama.ConsumerGroupSession, claim sarama.ConsumerGroupClaim) error {
	for {
		select {
		case message, ok := <-claim.Messages():
			if !ok {
				return nil
			}

			c.logger.WithFields(logrus.Fields{
				"topic":     message.Topic,
				"partition": message.Partition,
				"offset":    message.Offset,
			}).Debug("Received biometric event")

			if err := c.processMessage(message); err != nil {
				c.logger.WithError(err).Error("Failed to process biometric event")
			}

			session.MarkMessage(message, "")

		case <-session.Context().Done():
			return nil
		}
	}
}

func (c *BiometricEventConsumer) processMessage(message *sarama.ConsumerMessage) error {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	switch message.Topic {
	case "metachat.watch.data.received":
		var event BiometricEvent
		if err := json.Unmarshal(message.Value, &event); err != nil {
			return err
		}
		return c.handler.HandleWatchDataReceived(ctx, event.Payload)

	case "metachat.user.health.updated":
		var event UserHealthEvent
		if err := json.Unmarshal(message.Value, &event); err != nil {
			return err
		}
		return c.handler.HandleUserHealthUpdated(ctx, event.Payload)

	default:
		c.logger.WithField("topic", message.Topic).Warn("Unknown topic")
	}

	return nil
}

