package service

import (
	"context"
	"fmt"

	"metachat/match-request-service/internal/models"
	"metachat/match-request-service/internal/repository"

	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
)

type MatchRequestService interface {
	CreateMatchRequest(ctx context.Context, fromUserID, toUserID string, commonTopics []string, similarity float64) (*models.MatchRequest, error)
	GetUserMatchRequests(ctx context.Context, userID string, status string) ([]*models.MatchRequest, error)
	AcceptMatchRequest(ctx context.Context, requestID, userID string) (*models.MatchRequest, error)
	RejectMatchRequest(ctx context.Context, requestID, userID string) (*models.MatchRequest, error)
	GetMatchRequest(ctx context.Context, requestID string) (*models.MatchRequest, error)
	CancelMatchRequest(ctx context.Context, requestID, userID string) (*models.MatchRequest, error)
}

type matchRequestService struct {
	repository repository.MatchRequestRepository
	logger     *logrus.Logger
}

func NewMatchRequestService(repo repository.MatchRequestRepository, logger *logrus.Logger) MatchRequestService {
	return &matchRequestService{
		repository: repo,
		logger:     logger,
	}
}

func (s *matchRequestService) CreateMatchRequest(ctx context.Context, fromUserID, toUserID string, commonTopics []string, similarity float64) (*models.MatchRequest, error) {
	if fromUserID == toUserID {
		return nil, fmt.Errorf("cannot create match request to yourself")
	}

	req := &models.MatchRequest{
		ID:           uuid.New().String(),
		FromUserID:   fromUserID,
		ToUserID:     toUserID,
		CommonTopics: commonTopics,
		Similarity:   similarity,
		Status:       models.StatusPending,
	}

	err := s.repository.CreateMatchRequest(ctx, req)
	if err != nil {
		s.logger.WithError(err).Error("Failed to create match request")
		return nil, err
	}

	s.logger.WithFields(logrus.Fields{
		"request_id":  req.ID,
		"from_user":   fromUserID,
		"to_user":     toUserID,
		"similarity":  similarity,
	}).Info("Match request created")

	return req, nil
}

func (s *matchRequestService) GetUserMatchRequests(ctx context.Context, userID string, status string) ([]*models.MatchRequest, error) {
	requests, err := s.repository.GetUserMatchRequests(ctx, userID, status)
	if err != nil {
		s.logger.WithError(err).Error("Failed to get user match requests")
		return nil, err
	}

	return requests, nil
}

func (s *matchRequestService) AcceptMatchRequest(ctx context.Context, requestID, userID string) (*models.MatchRequest, error) {
	req, err := s.repository.GetMatchRequestByID(ctx, requestID)
	if err != nil {
		return nil, err
	}

	if req.ToUserID != userID {
		return nil, fmt.Errorf("user is not authorized to accept this request")
	}

	if req.Status != models.StatusPending {
		return nil, fmt.Errorf("match request is not pending")
	}

	err = s.repository.UpdateMatchRequestStatus(ctx, requestID, models.StatusAccepted)
	if err != nil {
		s.logger.WithError(err).Error("Failed to accept match request")
		return nil, err
	}

	req.Status = models.StatusAccepted
	s.logger.WithFields(logrus.Fields{
		"request_id": requestID,
		"user_id":    userID,
	}).Info("Match request accepted")

	return req, nil
}

func (s *matchRequestService) RejectMatchRequest(ctx context.Context, requestID, userID string) (*models.MatchRequest, error) {
	req, err := s.repository.GetMatchRequestByID(ctx, requestID)
	if err != nil {
		return nil, err
	}

	if req.ToUserID != userID {
		return nil, fmt.Errorf("user is not authorized to reject this request")
	}

	if req.Status != models.StatusPending {
		return nil, fmt.Errorf("match request is not pending")
	}

	err = s.repository.UpdateMatchRequestStatus(ctx, requestID, models.StatusRejected)
	if err != nil {
		s.logger.WithError(err).Error("Failed to reject match request")
		return nil, err
	}

	req.Status = models.StatusRejected
	s.logger.WithFields(logrus.Fields{
		"request_id": requestID,
		"user_id":    userID,
	}).Info("Match request rejected")

	return req, nil
}

func (s *matchRequestService) GetMatchRequest(ctx context.Context, requestID string) (*models.MatchRequest, error) {
	req, err := s.repository.GetMatchRequestByID(ctx, requestID)
	if err != nil {
		s.logger.WithError(err).Error("Failed to get match request")
		return nil, err
	}

	return req, nil
}

func (s *matchRequestService) CancelMatchRequest(ctx context.Context, requestID, userID string) (*models.MatchRequest, error) {
	req, err := s.repository.GetMatchRequestByID(ctx, requestID)
	if err != nil {
		return nil, err
	}

	if req.FromUserID != userID {
		return nil, fmt.Errorf("user is not authorized to cancel this request")
	}

	if req.Status != models.StatusPending {
		return nil, fmt.Errorf("only pending requests can be cancelled")
	}

	err = s.repository.UpdateMatchRequestStatus(ctx, requestID, models.StatusCancelled)
	if err != nil {
		s.logger.WithError(err).Error("Failed to cancel match request")
		return nil, err
	}

	req.Status = models.StatusCancelled
	s.logger.WithFields(logrus.Fields{
		"request_id": requestID,
		"user_id":    userID,
	}).Info("Match request cancelled")

	return req, nil
}

