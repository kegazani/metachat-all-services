package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
	"github.com/sirupsen/logrus"

	"metachat/matching-service/internal/service"
)

// RecommendationHandler handles HTTP requests for recommendation operations
type RecommendationHandler struct {
	recommendationService service.RecommendationService
	logger                *logrus.Logger
}

// NewRecommendationHandler creates a new recommendation handler
func NewRecommendationHandler(recommendationService service.RecommendationService) *RecommendationHandler {
	return &RecommendationHandler{
		recommendationService: recommendationService,
		logger:                logrus.New(),
	}
}

// RegisterRoutes registers routes for the recommendation handler
func (h *RecommendationHandler) RegisterRoutes(router *mux.Router) {
	// Recommendation routes
	router.HandleFunc("/users/{id}/recommendations/content", h.GetContentRecommendations).Methods("GET")
	router.HandleFunc("/users/{id}/recommendations/users", h.GetUserRecommendations).Methods("GET")
	router.HandleFunc("/content/{id}/similar", h.GetSimilarContent).Methods("GET")
}

// GetContentRecommendations handles request to get content recommendations for a user
func (h *RecommendationHandler) GetContentRecommendations(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userID := vars["id"]

	// Parse limit from query parameters
	limit := 10 // Default limit
	if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
		if parsedLimit, err := strconv.Atoi(limitStr); err == nil && parsedLimit > 0 {
			limit = parsedLimit
		}
	}

	recommendations, err := h.recommendationService.GetContentRecommendations(r.Context(), userID, limit)
	if err != nil {
		h.logger.WithError(err).Error("Failed to get content recommendations")
		http.Error(w, "Failed to get content recommendations", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(recommendations)
}

// GetUserRecommendations handles request to get user recommendations for a user
func (h *RecommendationHandler) GetUserRecommendations(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userID := vars["id"]

	// Parse limit from query parameters
	limit := 10 // Default limit
	if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
		if parsedLimit, err := strconv.Atoi(limitStr); err == nil && parsedLimit > 0 {
			limit = parsedLimit
		}
	}

	matches, err := h.recommendationService.GetUserRecommendations(r.Context(), userID, limit)
	if err != nil {
		h.logger.WithError(err).Error("Failed to get user recommendations")
		http.Error(w, "Failed to get user recommendations", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(matches)
}

// GetSimilarContent handles request to get content similar to given content
func (h *RecommendationHandler) GetSimilarContent(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	contentID := vars["id"]

	// Parse limit from query parameters
	limit := 10 // Default limit
	if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
		if parsedLimit, err := strconv.Atoi(limitStr); err == nil && parsedLimit > 0 {
			limit = parsedLimit
		}
	}

	similarContent, err := h.recommendationService.GetSimilarContent(r.Context(), contentID, limit)
	if err != nil {
		h.logger.WithError(err).Error("Failed to get similar content")
		http.Error(w, "Failed to get similar content", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(similarContent)
}
