package main

import (
	"context"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gorilla/mux"
	"github.com/sirupsen/logrus"
	"github.com/spf13/viper"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"

	"metachat/matching-service/internal/api"
	grpcServer "metachat/matching-service/internal/grpc"
	"metachat/matching-service/internal/handlers"
	"metachat/matching-service/internal/repository"
	"metachat/matching-service/internal/service"

	pb "github.com/kegazani/metachat-proto/matching"
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
	httpPort := viper.GetString("server.http_port")
	if httpPort == "" {
		httpPort = "8080"
	}

	srv := &http.Server{
		Addr:         ":" + httpPort,
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start HTTP server in a goroutine
	go func() {
		logger.Infof("Starting HTTP server on port %s", httpPort)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatalf("Failed to start HTTP server: %v", err)
		}
	}()

	// Initialize gRPC server
	grpcPort := viper.GetString("server.grpc_port")
	if grpcPort == "" {
		grpcPort = "50053"
	}

	grpcHost := viper.GetString("server.host")
	if grpcHost == "" {
		grpcHost = "0.0.0.0"
	}

	grpcAddress := net.JoinHostPort(grpcHost, grpcPort)
	grpcLis, err := net.Listen("tcp", grpcAddress)
	if err != nil {
		logger.Fatalf("Failed to listen on %s: %v", grpcAddress, err)
	}

	grpcSrv := grpc.NewServer()
	grpcMatchingServer := grpcServer.NewMatchingServer(matchingService, logger)
	pb.RegisterMatchingServiceServer(grpcSrv, grpcMatchingServer)

	if viper.GetBool("grpc.reflection_enabled") {
		reflection.Register(grpcSrv)
		logger.Info("gRPC reflection enabled")
	}

	// Start gRPC server in a goroutine
	go func() {
		logger.Infof("Starting gRPC server on %s", grpcAddress)
		if err := grpcSrv.Serve(grpcLis); err != nil {
			logger.Fatalf("Failed to start gRPC server: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("Shutting down servers...")

	// Create context with timeout for graceful shutdown
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Shutdown HTTP server
	if err := srv.Shutdown(ctx); err != nil {
		logger.Errorf("HTTP server forced to shutdown: %v", err)
	}

	// Shutdown gRPC server
	done := make(chan struct{})
	go func() {
		grpcSrv.GracefulStop()
		close(done)
	}()

	select {
	case <-done:
		logger.Info("gRPC server exited gracefully")
	case <-ctx.Done():
		logger.Info("gRPC server shutdown timeout")
		grpcSrv.Stop()
	}

	logger.Info("Server exited")
}
