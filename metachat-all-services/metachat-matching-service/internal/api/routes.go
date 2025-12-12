package api

import (
	"net/http"

	"github.com/gorilla/mux"

	"metachat/matching-service/internal/handlers"
)

// SetupRoutes sets up all the routes for the API
func SetupRoutes(router *mux.Router, userHandler *handlers.UserHandler, matchingHandler *handlers.MatchingHandler, recommendationHandler *handlers.RecommendationHandler) {
	// Register routes for each handler
	userHandler.RegisterRoutes(router)
	matchingHandler.RegisterRoutes(router)
	recommendationHandler.RegisterRoutes(router)

	// Health check endpoint
	router.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status": "ok"}`))
	}).Methods("GET")

	// API version endpoint
	router.HandleFunc("/version", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"version": "1.0.0"}`))
	}).Methods("GET")
}
