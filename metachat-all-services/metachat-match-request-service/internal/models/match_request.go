package models

import (
	"time"
)

type MatchRequest struct {
	ID           string
	FromUserID   string
	ToUserID     string
	CommonTopics []string
	Similarity   float64
	Status       string
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

const (
	StatusPending  = "pending"
	StatusAccepted = "accepted"
	StatusRejected = "rejected"
	StatusCancelled = "cancelled"
)

