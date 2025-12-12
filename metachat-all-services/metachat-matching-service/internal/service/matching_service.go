package service

import (
	"context"
	"time"

	"metachat/matching-service/internal/repository"
)

// MatchingService defines the interface for matching service operations
type MatchingService interface {
	// FindSimilarUsers finds users similar to the given user
	FindSimilarUsers(ctx context.Context, userID string, limit int) ([]*repository.UserMatch, error)

	// CalculateUserSimilarity calculates the similarity between two users
	CalculateUserSimilarity(ctx context.Context, userID1, userID2 string) (float64, error)

	// SaveUserMatch saves a user match
	SaveUserMatch(ctx context.Context, match *repository.UserMatch) error

	// GetUserMatches retrieves all matches for a user
	GetUserMatches(ctx context.Context, userID string) ([]*repository.UserMatch, error)

	// GetCommonTopics retrieves common topics between two users
	GetCommonTopics(ctx context.Context, userID1, userID2 string) ([]string, error)
}

// matchingService is the implementation of MatchingService
type matchingService struct {
	matchingRepository repository.MatchingRepository
	userRepository     repository.UserRepository
}

// NewMatchingService creates a new matching service
func NewMatchingService(matchingRepository repository.MatchingRepository, userRepository repository.UserRepository) MatchingService {
	return &matchingService{
		matchingRepository: matchingRepository,
		userRepository:     userRepository,
	}
}

// FindSimilarUsers finds users similar to the given user
func (s *matchingService) FindSimilarUsers(ctx context.Context, userID string, limit int) ([]*repository.UserMatch, error) {
	// Get user portrait
	userPortrait, err := s.userRepository.GetUserPortrait(ctx, userID)
	if err != nil {
		return nil, err
	}

	// Find similar users
	matches, err := s.matchingRepository.FindSimilarUsers(ctx, userID, limit)
	if err != nil {
		return nil, err
	}

	// Calculate similarity for each match
	for _, match := range matches {
		// Get the other user's portrait
		otherUserID := match.UserID2
		if otherUserID == userID {
			otherUserID = match.UserID1
		}

		otherPortrait, err := s.userRepository.GetUserPortrait(ctx, otherUserID)
		if err != nil {
			continue
		}

		// Calculate similarity
		similarity := repository.CalculateSimilarity(userPortrait, otherPortrait)
		match.Similarity = similarity
	}

	// Sort by similarity (descending)
	for i := 0; i < len(matches)-1; i++ {
		for j := i + 1; j < len(matches); j++ {
			if matches[i].Similarity < matches[j].Similarity {
				matches[i], matches[j] = matches[j], matches[i]
			}
		}
	}

	// Limit results
	if len(matches) > limit {
		matches = matches[:limit]
	}

	return matches, nil
}

// CalculateUserSimilarity calculates the similarity between two users
func (s *matchingService) CalculateUserSimilarity(ctx context.Context, userID1, userID2 string) (float64, error) {
	// Get user portraits
	portrait1, err := s.userRepository.GetUserPortrait(ctx, userID1)
	if err != nil {
		return 0, err
	}

	portrait2, err := s.userRepository.GetUserPortrait(ctx, userID2)
	if err != nil {
		return 0, err
	}

	// Calculate similarity
	similarity := repository.CalculateSimilarity(portrait1, portrait2)

	return similarity, nil
}

// SaveUserMatch saves a user match
func (s *matchingService) SaveUserMatch(ctx context.Context, match *repository.UserMatch) error {
	// Set created at if not set
	if match.CreatedAt == "" {
		match.CreatedAt = time.Now().Format(time.RFC3339)
	}

	return s.matchingRepository.SaveUserMatch(ctx, match)
}

// GetUserMatches retrieves all matches for a user
func (s *matchingService) GetUserMatches(ctx context.Context, userID string) ([]*repository.UserMatch, error) {
	return s.matchingRepository.GetUserMatches(ctx, userID)
}

// GetCommonTopics retrieves common topics between two users
func (s *matchingService) GetCommonTopics(ctx context.Context, userID1, userID2 string) ([]string, error) {
	portrait1, err := s.userRepository.GetUserPortrait(ctx, userID1)
	if err != nil {
		return nil, err
	}

	portrait2, err := s.userRepository.GetUserPortrait(ctx, userID2)
	if err != nil {
		return nil, err
	}

	return repository.GetCommonTopics(portrait1, portrait2), nil
}
