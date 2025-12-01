package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/sirupsen/logrus"

	"metachat/matching-service/internal/service"
)

// UserHandler handles HTTP requests for user operations
type UserHandler struct {
	userService service.UserService
	logger      *logrus.Logger
}

// NewUserHandler creates a new user handler
func NewUserHandler(userService service.UserService) *UserHandler {
	return &UserHandler{
		userService: userService,
		logger:      logrus.New(),
	}
}

// RegisterRoutes registers the routes for the user handler
func (h *UserHandler) RegisterRoutes(router *mux.Router) {
	// User routes
	router.HandleFunc("/users/{id}", h.GetUserByID).Methods("GET")
	router.HandleFunc("/users/{id}/portrait", h.GetUserPortrait).Methods("GET")
	router.HandleFunc("/users/{id}/portrait", h.UpdateUserPortrait).Methods("PUT")
}

// GetUserByID handles the request to get a user by ID
func (h *UserHandler) GetUserByID(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userID := vars["id"]

	user, err := h.userService.GetUserByID(r.Context(), userID)
	if err != nil {
		h.logger.WithError(err).Error("Failed to get user")
		http.Error(w, "Failed to get user", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(user)
}

// GetUserPortrait handles the request to get a user's portrait
func (h *UserHandler) GetUserPortrait(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userID := vars["id"]

	portrait, err := h.userService.GetUserPortrait(r.Context(), userID)
	if err != nil {
		h.logger.WithError(err).Error("Failed to get user portrait")
		http.Error(w, "Failed to get user portrait", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(portrait)
}

// UpdateUserPortrait handles the request to update a user's portrait
func (h *UserHandler) UpdateUserPortrait(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userID := vars["id"]

	var portrait service.UserPortrait
	if err := json.NewDecoder(r.Body).Decode(&portrait); err != nil {
		h.logger.WithError(err).Error("Failed to decode request body")
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if err := h.userService.UpdateUserPortrait(r.Context(), userID, &portrait); err != nil {
		h.logger.WithError(err).Error("Failed to update user portrait")
		http.Error(w, "Failed to update user portrait", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(portrait)
}
