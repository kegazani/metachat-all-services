package models

import (
	"time"

	"github.com/kegazani/metachat-event-sourcing/events"
)

type UserBiometricData struct {
	CurrentHeartRate       *float64  `cql:"current_heart_rate" json:"current_heart_rate,omitempty"`
	RestingHeartRate       *float64  `cql:"resting_heart_rate" json:"resting_heart_rate,omitempty"`
	AvgHRV                 *float64  `cql:"avg_hrv" json:"avg_hrv,omitempty"`
	AvgBloodOxygen         *float64  `cql:"avg_blood_oxygen" json:"avg_blood_oxygen,omitempty"`
	AvgStressLevel         *float64  `cql:"avg_stress_level" json:"avg_stress_level,omitempty"`
	TodaySteps             *int      `cql:"today_steps" json:"today_steps,omitempty"`
	TodayCalories          *float64  `cql:"today_calories" json:"today_calories,omitempty"`
	LastSleepScore         *int      `cql:"last_sleep_score" json:"last_sleep_score,omitempty"`
	LastSleepDurationHours *float64  `cql:"last_sleep_duration_hours" json:"last_sleep_duration_hours,omitempty"`
	HealthScore            *int      `cql:"health_score" json:"health_score,omitempty"`
	DeviceType             *string   `cql:"device_type" json:"device_type,omitempty"`
	LastSync               *time.Time `cql:"last_sync" json:"last_sync,omitempty"`
}

type UserReadModel struct {
	ID                   string             `cql:"id"`
	Username             string             `cql:"username"`
	Email                string             `cql:"email"`
	FirstName            string             `cql:"first_name"`
	LastName             string             `cql:"last_name"`
	DateOfBirth          string             `cql:"date_of_birth"`
	Avatar               string             `cql:"avatar"`
	Bio                  string             `cql:"bio"`
	ArchetypeID          string             `cql:"archetype_id"`
	ArchetypeName        string             `cql:"archetype_name"`
	ArchetypeScore       float64            `cql:"archetype_score"`
	ArchetypeDescription string             `cql:"archetype_description"`
	Modalities           []UserModalityRead `cql:"modalities"`
	PasswordHash         string             `cql:"password_hash"`
	Biometric            *UserBiometricData `cql:"biometric" json:"biometric,omitempty"`
	CreatedAt            time.Time          `cql:"created_at"`
	UpdatedAt            time.Time          `cql:"updated_at"`
	Version              int                `cql:"version"`
}

func (u *UserReadModel) UpdateBiometricData(data *UserBiometricData) {
	if u.Biometric == nil {
		u.Biometric = &UserBiometricData{}
	}
	
	if data.CurrentHeartRate != nil {
		u.Biometric.CurrentHeartRate = data.CurrentHeartRate
	}
	if data.RestingHeartRate != nil {
		u.Biometric.RestingHeartRate = data.RestingHeartRate
	}
	if data.AvgHRV != nil {
		u.Biometric.AvgHRV = data.AvgHRV
	}
	if data.AvgBloodOxygen != nil {
		u.Biometric.AvgBloodOxygen = data.AvgBloodOxygen
	}
	if data.AvgStressLevel != nil {
		u.Biometric.AvgStressLevel = data.AvgStressLevel
	}
	if data.TodaySteps != nil {
		u.Biometric.TodaySteps = data.TodaySteps
	}
	if data.TodayCalories != nil {
		u.Biometric.TodayCalories = data.TodayCalories
	}
	if data.LastSleepScore != nil {
		u.Biometric.LastSleepScore = data.LastSleepScore
	}
	if data.LastSleepDurationHours != nil {
		u.Biometric.LastSleepDurationHours = data.LastSleepDurationHours
	}
	if data.HealthScore != nil {
		u.Biometric.HealthScore = data.HealthScore
	}
	if data.DeviceType != nil {
		u.Biometric.DeviceType = data.DeviceType
	}
	if data.LastSync != nil {
		u.Biometric.LastSync = data.LastSync
	}
	
	u.UpdatedAt = time.Now()
}

// UserModalityRead represents the read model for user modalities
type UserModalityRead struct {
	ID      string                 `cql:"id"`
	Name    string                 `cql:"name"`
	Type    string                 `cql:"type"`
	Enabled bool                   `cql:"enabled"`
	Weight  float64                `cql:"weight"`
	Config  map[string]interface{} `cql:"config"`
}

// UserByUsernameReadModel represents a read model optimized for username lookups
type UserByUsernameReadModel struct {
	Username string `cql:"username"`
	UserID   string `cql:"user_id"`
	Email    string `cql:"email"`
}

// UserByEmailReadModel represents a read model optimized for email lookups
type UserByEmailReadModel struct {
	Email    string `cql:"email"`
	UserID   string `cql:"user_id"`
	Username string `cql:"username"`
}

// NewUserReadModelFromEvent creates a new UserReadModel from a UserRegistered event
func NewUserReadModelFromEvent(event *events.Event) (*UserReadModel, error) {
	var payload events.UserRegisteredPayload
	if err := event.UnmarshalPayload(&payload); err != nil {
		return nil, err
	}

	return &UserReadModel{
		ID:          event.AggregateID,
		Username:    payload.Username,
		Email:       payload.Email,
		FirstName:   payload.FirstName,
		LastName:    payload.LastName,
		DateOfBirth: payload.DateOfBirth,
		CreatedAt:   event.Timestamp,
		UpdatedAt:   event.Timestamp,
		Version:     event.Version,
	}, nil
}

// NewUserByUsernameReadModel creates a new UserByUsernameReadModel from a UserRegistered event
func NewUserByUsernameReadModelFromEvent(event *events.Event) (*UserByUsernameReadModel, error) {
	var payload events.UserRegisteredPayload
	if err := event.UnmarshalPayload(&payload); err != nil {
		return nil, err
	}

	return &UserByUsernameReadModel{
		Username: payload.Username,
		UserID:   event.AggregateID,
		Email:    payload.Email,
	}, nil
}

// NewUserByEmailReadModel creates a new UserByEmailReadModel from a UserRegistered event
func NewUserByEmailReadModelFromEvent(event *events.Event) (*UserByEmailReadModel, error) {
	var payload events.UserRegisteredPayload
	if err := event.UnmarshalPayload(&payload); err != nil {
		return nil, err
	}

	return &UserByEmailReadModel{
		Email:    payload.Email,
		UserID:   event.AggregateID,
		Username: payload.Username,
	}, nil
}

// UpdateFromProfileUpdateEvent updates the UserReadModel from a UserProfileUpdated event
func (u *UserReadModel) UpdateFromProfileUpdateEvent(event *events.Event) error {
	var payload events.UserProfileUpdatedPayload
	if err := event.UnmarshalPayload(&payload); err != nil {
		return err
	}

	if payload.FirstName != "" {
		u.FirstName = payload.FirstName
	}
	if payload.LastName != "" {
		u.LastName = payload.LastName
	}
	if payload.DateOfBirth != "" {
		u.DateOfBirth = payload.DateOfBirth
	}
	if payload.Avatar != "" {
		u.Avatar = payload.Avatar
	}
	if payload.Bio != "" {
		u.Bio = payload.Bio
	}

	u.UpdatedAt = event.Timestamp
	u.Version = event.Version
	return nil
}

// UpdateFromArchetypeAssignedEvent updates the UserReadModel from a UserArchetypeAssigned event
func (u *UserReadModel) UpdateFromArchetypeAssignedEvent(event *events.Event) error {
	var payload events.UserArchetypeAssignedPayload
	if err := event.UnmarshalPayload(&payload); err != nil {
		return err
	}

	u.ArchetypeID = payload.ArchetypeID
	u.ArchetypeName = payload.ArchetypeName
	u.ArchetypeScore = payload.Confidence
	u.ArchetypeDescription = payload.Description
	u.UpdatedAt = event.Timestamp
	u.Version = event.Version
	return nil
}

// UpdateFromArchetypeUpdatedEvent updates the UserReadModel from a UserArchetypeUpdated event
func (u *UserReadModel) UpdateFromArchetypeUpdatedEvent(event *events.Event) error {
	var payload events.UserArchetypeUpdatedPayload
	if err := event.UnmarshalPayload(&payload); err != nil {
		return err
	}

	u.ArchetypeID = payload.ArchetypeID
	u.ArchetypeName = payload.ArchetypeName
	u.ArchetypeScore = payload.Confidence
	u.ArchetypeDescription = payload.Description
	u.UpdatedAt = event.Timestamp
	u.Version = event.Version
	return nil
}

// UpdateFromModalitiesUpdatedEvent updates the UserReadModel from a UserModalitiesUpdated event
func (u *UserReadModel) UpdateFromModalitiesUpdatedEvent(event *events.Event) error {
	var payload events.UserModalitiesUpdatedPayload
	if err := event.UnmarshalPayload(&payload); err != nil {
		return err
	}

	u.Modalities = make([]UserModalityRead, len(payload.Modalities))
	for i, modality := range payload.Modalities {
		u.Modalities[i] = UserModalityRead{
			ID:      modality.ID,
			Name:    modality.Name,
			Type:    modality.Type,
			Enabled: modality.Enabled,
			Weight:  modality.Weight,
			Config:  modality.Config,
		}
	}

	u.UpdatedAt = event.Timestamp
	u.Version = event.Version
	return nil
}

// ToUserModality converts UserModalityRead to events.UserModality
func (u *UserModalityRead) ToUserModality() events.UserModality {
	return events.UserModality{
		ID:      u.ID,
		Name:    u.Name,
		Type:    u.Type,
		Enabled: u.Enabled,
		Weight:  u.Weight,
		Config:  u.Config,
	}
}

// ToUserModalities converts []UserModalityRead to []events.UserModality
func ToUserModalities(modalities []UserModalityRead) []events.UserModality {
	result := make([]events.UserModality, len(modalities))
	for i, modality := range modalities {
		result[i] = modality.ToUserModality()
	}
	return result
}
