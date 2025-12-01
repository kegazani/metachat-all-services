package service

import (
	"context"

	"metachat/matching-service/internal/repository"
)

// UserService defines the interface for user service operations
type UserService interface {
	// GetUserByID retrieves a user by ID
	GetUserByID(ctx context.Context, userID string) (*repository.User, error)

	// GetUserPortrait retrieves a user's portrait
	GetUserPortrait(ctx context.Context, userID string) (*repository.UserPortrait, error)

	// UpdateUserPortrait updates a user's portrait
	UpdateUserPortrait(ctx context.Context, userID string, portrait *repository.UserPortrait) error
}

// userService is the implementation of UserService
type userService struct {
	userRepository repository.UserRepository
}

// NewUserService creates a new user service
func NewUserService(userRepository repository.UserRepository) UserService {
	return &userService{
		userRepository: userRepository,
	}
}

// GetUserByID retrieves a user by ID
func (s *userService) GetUserByID(ctx context.Context, userID string) (*repository.User, error) {
	return s.userRepository.GetUserByID(ctx, userID)
}

// GetUserPortrait retrieves a user's portrait
func (s *userService) GetUserPortrait(ctx context.Context, userID string) (*repository.UserPortrait, error) {
	return s.userRepository.GetUserPortrait(ctx, userID)
}

// UpdateUserPortrait updates a user's portrait
func (s *userService) UpdateUserPortrait(ctx context.Context, userID string, portrait *repository.UserPortrait) error {
	return s.userRepository.UpdateUserPortrait(ctx, userID, portrait)
}
