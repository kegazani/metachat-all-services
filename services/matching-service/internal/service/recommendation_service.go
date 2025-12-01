package service

import (
	"context"
	"sort"

	"metachat/matching-service/internal/repository"
)

// RecommendationService defines the interface for recommendation service operations
type RecommendationService interface {
	// GetContentRecommendations gets content recommendations for a user
	GetContentRecommendations(ctx context.Context, userID string, limit int) ([]*ContentRecommendation, error)

	// GetUserRecommendations gets user recommendations for a user
	GetUserRecommendations(ctx context.Context, userID string, limit int) ([]*repository.UserMatch, error)

	// GetSimilarContent gets content similar to given content
	GetSimilarContent(ctx context.Context, contentID string, limit int) ([]*Content, error)
}

// Content represents a piece of content in the system
type Content struct {
	ID          string                 `json:"id"`
	Title       string                 `json:"title"`
	Description string                 `json:"description"`
	Type        string                 `json:"type"` // e.g., "article", "video", "podcast"
	Tags        []string               `json:"tags"`
	Metadata    map[string]interface{} `json:"metadata"`
	CreatedAt   string                 `json:"created_at"`
}

// ContentRecommendation represents a content recommendation
type ContentRecommendation struct {
	Content *Content `json:"content"`
	Score   float64  `json:"score"`
	Reason  string   `json:"reason"` // e.g., "similar_to_your_interests", "popular_in_your_community"
}

// recommendationService is the implementation of RecommendationService
type recommendationService struct {
	matchingRepository repository.MatchingRepository
}

// NewRecommendationService creates a new recommendation service
func NewRecommendationService(matchingRepository repository.MatchingRepository) RecommendationService {
	return &recommendationService{
		matchingRepository: matchingRepository,
	}
}

// GetContentRecommendations gets content recommendations for a user
func (s *recommendationService) GetContentRecommendations(ctx context.Context, userID string, limit int) ([]*ContentRecommendation, error) {
	// In a real implementation, this would query a content database
	// For now, we'll return mock data

	// Mock content
	content := []*Content{
		{
			ID:          "content_1",
			Title:       "Understanding Emotional Intelligence",
			Description: "Learn about the importance of emotional intelligence in personal and professional relationships.",
			Type:        "article",
			Tags:        []string{"psychology", "emotions", "self-improvement"},
			CreatedAt:   "2023-12-01T10:00:00Z",
		},
		{
			ID:          "content_2",
			Title:       "The Power of Vulnerability",
			Description: "A TED Talk by Brené Brown on the power of vulnerability in human connection.",
			Type:        "video",
			Tags:        []string{"psychology", "vulnerability", "connection"},
			CreatedAt:   "2023-12-01T10:00:00Z",
		},
		{
			ID:          "content_3",
			Title:       "Mindfulness Meditation for Beginners",
			Description: "A guided meditation for beginners to practice mindfulness.",
			Type:        "podcast",
			Tags:        []string{"meditation", "mindfulness", "wellness"},
			CreatedAt:   "2023-12-01T10:00:00Z",
		},
	}

	// Create recommendations
	recommendations := make([]*ContentRecommendation, len(content))
	for i, c := range content {
		recommendations[i] = &ContentRecommendation{
			Content: c,
			Score:   0.9 - float64(i)*0.1, // Decreasing score
			Reason:  "similar_to_your_interests",
		}
	}

	// Sort by score (descending)
	sort.Slice(recommendations, func(i, j int) bool {
		return recommendations[i].Score > recommendations[j].Score
	})

	// Limit results
	if len(recommendations) > limit {
		recommendations = recommendations[:limit]
	}

	return recommendations, nil
}

// GetUserRecommendations gets user recommendations for a user
func (s *recommendationService) GetUserRecommendations(ctx context.Context, userID string, limit int) ([]*repository.UserMatch, error) {
	// Get similar users
	matches, err := s.matchingRepository.FindSimilarUsers(ctx, userID, limit)
	if err != nil {
		return nil, err
	}

	// Filter matches with high similarity
	highSimilarityMatches := make([]*repository.UserMatch, 0)
	for _, match := range matches {
		if match.Similarity >= 0.7 { // Threshold for high similarity
			highSimilarityMatches = append(highSimilarityMatches, match)
		}
	}

	return highSimilarityMatches, nil
}

// GetSimilarContent gets content similar to given content
func (s *recommendationService) GetSimilarContent(ctx context.Context, contentID string, limit int) ([]*Content, error) {
	// In a real implementation, this would query a content database
	// For now, we'll return mock data

	// Mock content
	content := []*Content{
		{
			ID:          "content_1",
			Title:       "Understanding Emotional Intelligence",
			Description: "Learn about the importance of emotional intelligence in personal and professional relationships.",
			Type:        "article",
			Tags:        []string{"psychology", "emotions", "self-improvement"},
			CreatedAt:   "2023-12-01T10:00:00Z",
		},
		{
			ID:          "content_2",
			Title:       "The Power of Vulnerability",
			Description: "A TED Talk by Brené Brown on the power of vulnerability in human connection.",
			Type:        "video",
			Tags:        []string{"psychology", "vulnerability", "connection"},
			CreatedAt:   "2023-12-01T10:00:00Z",
		},
		{
			ID:          "content_3",
			Title:       "Mindfulness Meditation for Beginners",
			Description: "A guided meditation for beginners to practice mindfulness.",
			Type:        "podcast",
			Tags:        []string{"meditation", "mindfulness", "wellness"},
			CreatedAt:   "2023-12-01T10:00:00Z",
		},
		{
			ID:          "content_4",
			Title:       "The Science of Happiness",
			Description: "An exploration of what science tells us about happiness and how we can cultivate it.",
			Type:        "article",
			Tags:        []string{"psychology", "happiness", "science"},
			CreatedAt:   "2023-12-01T10:00:00Z",
		},
		{
			ID:          "content_5",
			Title:       "Building Resilience",
			Description: "Strategies for building resilience in the face of adversity.",
			Type:        "video",
			Tags:        []string{"psychology", "resilience", "self-improvement"},
			CreatedAt:   "2023-12-01T10:00:00Z",
		},
	}

	// Find content with the given ID
	var targetContent *Content
	for _, c := range content {
		if c.ID == contentID {
			targetContent = c
			break
		}
	}

	if targetContent == nil {
		return nil, nil
	}

	// Calculate similarity with other content
	type contentSimilarity struct {
		content    *Content
		similarity float64
	}

	similarities := make([]contentSimilarity, 0, len(content)-1)
	for _, c := range content {
		if c.ID != contentID {
			similarity := calculateContentSimilarity(targetContent, c)
			similarities = append(similarities, contentSimilarity{
				content:    c,
				similarity: similarity,
			})
		}
	}

	// Sort by similarity (descending)
	sort.Slice(similarities, func(i, j int) bool {
		return similarities[i].similarity > similarities[j].similarity
	})

	// Get the top N similar content
	result := make([]*Content, 0, limit)
	for i, cs := range similarities {
		if i >= limit {
			break
		}
		result = append(result, cs.content)
	}

	return result, nil
}

// calculateContentSimilarity calculates the similarity between two content items
func calculateContentSimilarity(content1, content2 *Content) float64 {
	// In a real implementation, this would use a more sophisticated algorithm
	// For now, we'll use a simple combination of type and tag similarity

	// Type similarity (1 if same type, 0 if different)
	typeSimilarity := 0.0
	if content1.Type == content2.Type {
		typeSimilarity = 1.0
	}

	// Tag similarity (Jaccard similarity)
	tagSimilarity := calculateTagSimilarity(content1.Tags, content2.Tags)

	// Weighted average
	weights := map[string]float64{
		"type": 0.3,
		"tags": 0.7,
	}

	similarity := weights["type"]*typeSimilarity + weights["tags"]*tagSimilarity

	return similarity
}

// calculateTagSimilarity calculates Jaccard similarity between two tag lists
func calculateTagSimilarity(tags1, tags2 []string) float64 {
	// Convert to sets
	set1 := make(map[string]bool)
	for _, tag := range tags1 {
		set1[tag] = true
	}

	set2 := make(map[string]bool)
	for _, tag := range tags2 {
		set2[tag] = true
	}

	// Calculate intersection and union
	intersection := 0
	for tag := range set1 {
		if set2[tag] {
			intersection++
		}
	}

	union := len(set1) + len(set2) - intersection

	if union == 0 {
		return 0.0
	}

	return float64(intersection) / float64(union)
}
