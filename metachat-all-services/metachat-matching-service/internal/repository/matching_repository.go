package repository

import (
	"context"
	"math"
	"sort"

	"github.com/sirupsen/logrus"
)

// MatchingRepository defines the interface for matching repository operations
type MatchingRepository interface {
	// FindSimilarUsers finds users similar to the given user
	FindSimilarUsers(ctx context.Context, userID string, limit int) ([]*UserMatch, error)

	// SaveUserMatch saves a user match
	SaveUserMatch(ctx context.Context, match *UserMatch) error

	// GetUserMatches retrieves all matches for a user
	GetUserMatches(ctx context.Context, userID string) ([]*UserMatch, error)
}

// GetCommonTopics extracts common topics from two user portraits
func GetCommonTopics(portrait1, portrait2 *UserPortrait) []string {
	if portrait1 == nil || portrait2 == nil {
		return []string{}
	}

	interests1 := make(map[string]bool)
	for _, interest := range portrait1.Interests {
		interests1[interest] = true
	}

	var commonTopics []string
	for _, interest := range portrait2.Interests {
		if interests1[interest] {
			commonTopics = append(commonTopics, interest)
		}
	}

	return commonTopics
}

// UserMatch represents a match between two users
type UserMatch struct {
	UserID1    string   `json:"user_id1"`
	UserID2    string   `json:"user_id2"`
	Similarity float64  `json:"similarity"`
	CommonTags []string `json:"common_tags"`
	CreatedAt  string   `json:"created_at"`
}

// matchingRepository is the implementation of MatchingRepository
type matchingRepository struct {
	logger *logrus.Logger
}

// NewMatchingRepository creates a new matching repository
func NewMatchingRepository() MatchingRepository {
	return &matchingRepository{
		logger: logrus.New(),
	}
}

// FindSimilarUsers finds users similar to the given user
func (r *matchingRepository) FindSimilarUsers(ctx context.Context, userID string, limit int) ([]*UserMatch, error) {
	// In a real implementation, this would query Cassandra or another database
	// For now, we'll return mock data

	// Mock data - in a real implementation, this would be calculated based on user portraits
	matches := []*UserMatch{
		{
			UserID1:    userID,
			UserID2:    "user_123",
			Similarity: 0.85,
			CommonTags: []string{"music", "reading"},
			CreatedAt:  "2023-12-01T10:00:00Z",
		},
		{
			UserID1:    userID,
			UserID2:    "user_456",
			Similarity: 0.72,
			CommonTags: []string{"travel", "music"},
			CreatedAt:  "2023-12-01T10:00:00Z",
		},
		{
			UserID1:    userID,
			UserID2:    "user_789",
			Similarity: 0.68,
			CommonTags: []string{"reading", "technology"},
			CreatedAt:  "2023-12-01T10:00:00Z",
		},
	}

	// Sort by similarity (descending)
	sort.Slice(matches, func(i, j int) bool {
		return matches[i].Similarity > matches[j].Similarity
	})

	// Limit results
	if len(matches) > limit {
		matches = matches[:limit]
	}

	return matches, nil
}

// SaveUserMatch saves a user match
func (r *matchingRepository) SaveUserMatch(ctx context.Context, match *UserMatch) error {
	// In a real implementation, this would save to Cassandra
	// For now, we'll just log it
	r.logger.Infof("Saving user match: %+v", match)
	return nil
}

// GetUserMatches retrieves all matches for a user
func (r *matchingRepository) GetUserMatches(ctx context.Context, userID string) ([]*UserMatch, error) {
	// In a real implementation, this would query Cassandra
	// For now, we'll return mock data
	return []*UserMatch{
		{
			UserID1:    userID,
			UserID2:    "user_123",
			Similarity: 0.85,
			CommonTags: []string{"music", "reading"},
			CreatedAt:  "2023-12-01T10:00:00Z",
		},
		{
			UserID1:    userID,
			UserID2:    "user_456",
			Similarity: 0.72,
			CommonTags: []string{"travel", "music"},
			CreatedAt:  "2023-12-01T10:00:00Z",
		},
	}, nil
}

// CalculateSimilarity calculates the similarity between two user portraits
func CalculateSimilarity(portrait1, portrait2 *UserPortrait) float64 {
	// In a real implementation, this would use a more sophisticated algorithm
	// For now, we'll use a simple weighted average of mood and personality similarity

	// Calculate mood similarity
	moodSimilarity := calculateMoodSimilarity(portrait1.MoodProfile, portrait2.MoodProfile)

	// Calculate personality similarity
	personalitySimilarity := calculatePersonalitySimilarity(portrait1.PersonalityTraits, portrait2.PersonalityTraits)

	// Calculate interest similarity
	interestSimilarity := calculateInterestSimilarity(portrait1.Interests, portrait2.Interests)

	// Calculate modality similarity
	modalitySimilarity := calculateModalitySimilarity(portrait1.Modalities, portrait2.Modalities)

	// Weighted average
	weights := map[string]float64{
		"mood":        0.4,
		"personality": 0.3,
		"interest":    0.2,
		"modality":    0.1,
	}

	similarity := weights["mood"]*moodSimilarity +
		weights["personality"]*personalitySimilarity +
		weights["interest"]*interestSimilarity +
		weights["modality"]*modalitySimilarity

	return similarity
}

// calculateMoodSimilarity calculates the similarity between two mood profiles
func calculateMoodSimilarity(mood1, mood2 map[string]float64) float64 {
	// In a real implementation, this would use a more sophisticated algorithm
	// For now, we'll use cosine similarity

	dotProduct := 0.0
	magnitude1 := 0.0
	magnitude2 := 0.0

	for mood, score1 := range mood1 {
		score2, exists := mood2[mood]
		if exists {
			dotProduct += score1 * score2
		}
		magnitude1 += score1 * score1
	}

	for _, score := range mood2 {
		magnitude2 += score * score
	}

	magnitude1 = math.Sqrt(magnitude1)
	magnitude2 = math.Sqrt(magnitude2)

	if magnitude1 == 0 || magnitude2 == 0 {
		return 0.0
	}

	return dotProduct / (magnitude1 * magnitude2)
}

// calculatePersonalitySimilarity calculates the similarity between two personality trait profiles
func calculatePersonalitySimilarity(traits1, traits2 map[string]float64) float64 {
	// In a real implementation, this would use a more sophisticated algorithm
	// For now, we'll use 1 minus the average absolute difference

	totalDiff := 0.0
	count := 0

	for trait, value1 := range traits1 {
		value2, exists := traits2[trait]
		if exists {
			totalDiff += math.Abs(value1 - value2)
			count++
		}
	}

	if count == 0 {
		return 0.0
	}

	avgDiff := totalDiff / float64(count)
	return 1.0 - avgDiff
}

// calculateInterestSimilarity calculates the similarity between two interest lists
func calculateInterestSimilarity(interests1, interests2 []string) float64 {
	// In a real implementation, this would use a more sophisticated algorithm
	// For now, we'll use Jaccard similarity

	set1 := make(map[string]bool)
	for _, interest := range interests1 {
		set1[interest] = true
	}

	set2 := make(map[string]bool)
	for _, interest := range interests2 {
		set2[interest] = true
	}

	intersection := 0
	for interest := range set1 {
		if set2[interest] {
			intersection++
		}
	}

	union := len(set1) + len(set2) - intersection

	if union == 0 {
		return 0.0
	}

	return float64(intersection) / float64(union)
}

// calculateModalitySimilarity calculates the similarity between two modality profiles
func calculateModalitySimilarity(modalities1, modalities2 map[string]interface{}) float64 {
	// In a real implementation, this would use a more sophisticated algorithm
	// For now, we'll use a simple average of absolute differences

	totalDiff := 0.0
	count := 0

	for modality, value1 := range modalities1 {
		value2, exists := modalities2[modality]
		if exists {
			// Convert to float64 for comparison
			v1, ok1 := value1.(float64)
			v2, ok2 := value2.(float64)
			if ok1 && ok2 {
				totalDiff += math.Abs(v1 - v2)
				count++
			}
		}
	}

	if count == 0 {
		return 0.0
	}

	avgDiff := totalDiff / float64(count)
	return 1.0 - avgDiff
}
