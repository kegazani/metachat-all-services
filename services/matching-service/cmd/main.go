package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gorilla/mux"
	"github.com/sirupsen/logrus"
	"github.com/spf13/viper"

	"metachat/matching-service/internal/api"
	"metachat/matching-service/internal/handlers"
	"metachat/matching-service/internal/repository"
	"metachat/matching-service/internal/service"
)

func main() {
	// Initialize logger
	logger := logrus.New()
	logger.SetFormatter(&logrus.JSONFormatter{})
	logger.SetOutput(os.Stdout)
	logger.SetLevel(logrus.InfoLevel)

	// Load configuration
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath("./config")
	viper.AddConfigPath("/app/config")

	if err := viper.ReadInConfig(); err != nil {
		logger.Fatalf("Failed to read config file: %v", err)
	}

	// Initialize repositories
	userRepository := repository.NewUserRepository()
	matchingRepository := repository.NewMatchingRepository()

	// Initialize services
	userService := service.NewUserService(userRepository)
	matchingService := service.NewMatchingService(matchingRepository, userRepository)
	recommendationService := service.NewRecommendationService(matchingRepository)

	// Initialize handlers
	userHandler := handlers.NewUserHandler(userService)
	matchingHandler := handlers.NewMatchingHandler(matchingService)
	recommendationHandler := handlers.NewRecommendationHandler(recommendationService)

	// Initialize API
	router := mux.NewRouter()
	api.SetupRoutes(router, userHandler, matchingHandler, recommendationHandler)

	// Create HTTP server
	port := viper.GetString("server.port")
	if port == "" {
		port = "8080"
	}

	srv := &http.Server{
		Addr:         ":" + port,
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start server in a goroutine
	go func() {
		logger.Infof("Starting server on port %s", port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("Shutting down server...")

	// Create context with timeout for graceful shutdown
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		logger.Errorf("Server forced to shutdown: %v", err)
	}

	logger.Info("Server exited")
}
