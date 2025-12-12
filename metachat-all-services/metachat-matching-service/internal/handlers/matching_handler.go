package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
	"github.com/sirupsen/logrus"

	"metachat/matching-service/internal/service"
)

// MatchingHandler handles HTTP requests for matching operations
type MatchingHandler struct {
	matchingService service.MatchingService
	logger          *logrus.Logger
}

// NewMatchingHandler creates a new matching handler
func NewMatchingHandler(matchingService service.MatchingService) *MatchingHandler {
	return &MatchingHandler{
		matchingService: matchingService,
		logger:          logrus.New(),
	}
}

// RegisterRoutes registers the routes for the matching handler
func (h *MatchingHandler) RegisterRoutes(router *mux.Router) {
	// Matching routes
	router.HandleFunc("/users/{id}/similar", h.FindSimilarUsers).Methods("GET")
	router.HandleFunc("/users/{id1}/similarity/{id2}", h.CalculateUserSimilarity).Methods("GET")
	router.HandleFunc("/users/{id}/matches", h.GetUserMatches).Methods("GET")
	router.HandleFunc("/users/{id1}/common-topics/{id2}", h.GetCommonTopics).Methods("GET")
}

// FindSimilarUsers handles the request to find similar users
func (h *MatchingHandler) FindSimilarUsers(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userID := vars["id"]

	// Parse limit from query parameters
	limit := 10 // Default limit
	if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
		if parsedLimit, err := strconv.Atoi(limitStr); err == nil && parsedLimit > 0 {
			limit = parsedLimit
		}
	}

	matches, err := h.matchingService.FindSimilarUsers(r.Context(), userID, limit)
	if err != nil {
		h.logger.WithError(err).Error("Failed to find similar users")
		http.Error(w, "Failed to find similar users", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(matches)
}

// CalculateUserSimilarity handles the request to calculate similarity between two users
func (h *MatchingHandler) CalculateUserSimilarity(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userID1 := vars["id1"]
	userID2 := vars["id2"]

	similarity, err := h.matchingService.CalculateUserSimilarity(r.Context(), userID1, userID2)
	if err != nil {
		h.logger.WithError(err).Error("Failed to calculate user similarity")
		http.Error(w, "Failed to calculate user similarity", http.StatusInternalServerError)
		return
	}

	result := map[string]float64{
		"similarity": similarity,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(result)
}

// GetUserMatches handles the request to get all matches for a user
func (h *MatchingHandler) GetUserMatches(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userID := vars["id"]

	matches, err := h.matchingService.GetUserMatches(r.Context(), userID)
	if err != nil {
		h.logger.WithError(err).Error("Failed to get user matches")
		http.Error(w, "Failed to get user matches", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(matches)
}

// GetCommonTopics handles the request to get common topics between two users
func (h *MatchingHandler) GetCommonTopics(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userID1 := vars["id1"]
	userID2 := vars["id2"]

	topics, err := h.matchingService.GetCommonTopics(r.Context(), userID1, userID2)
	if err != nil {
		h.logger.WithError(err).Error("Failed to get common topics")
		http.Error(w, "Failed to get common topics", http.StatusInternalServerError)
		return
	}

	result := map[string]interface{}{
		"common_topics": topics,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(result)
}
