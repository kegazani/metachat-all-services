package grpc

import (
	"context"

	"metachat/match-request-service/internal/models"
	"metachat/match-request-service/internal/service"

	"github.com/sirupsen/logrus"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"

	pb "github.com/kegazani/metachat-proto/match_request"
)

type MatchRequestServer struct {
	pb.UnimplementedMatchRequestServiceServer
	service service.MatchRequestService
	logger  *logrus.Logger
}

func NewMatchRequestServer(svc service.MatchRequestService, logger *logrus.Logger) *MatchRequestServer {
	return &MatchRequestServer{
		service: svc,
		logger:  logger,
	}
}

func (s *MatchRequestServer) CreateMatchRequest(ctx context.Context, req *pb.CreateMatchRequestRequest) (*pb.CreateMatchRequestResponse, error) {
	s.logger.WithFields(logrus.Fields{
		"from_user_id": req.FromUserId,
		"to_user_id":   req.ToUserId,
	}).Info("Creating match request via gRPC")

	matchReq, err := s.service.CreateMatchRequest(ctx, req.FromUserId, req.ToUserId, req.CommonTopics, req.Similarity)
	if err != nil {
		s.logger.WithError(err).Error("Failed to create match request")
		return nil, status.Errorf(codes.Internal, "failed to create match request: %v", err)
	}

	return &pb.CreateMatchRequestResponse{
		MatchRequest: s.matchRequestToProto(matchReq),
	}, nil
}

func (s *MatchRequestServer) GetUserMatchRequests(ctx context.Context, req *pb.GetUserMatchRequestsRequest) (*pb.GetUserMatchRequestsResponse, error) {
	s.logger.WithField("user_id", req.UserId).Info("Getting user match requests via gRPC")

	requests, err := s.service.GetUserMatchRequests(ctx, req.UserId, req.Status)
	if err != nil {
		s.logger.WithError(err).Error("Failed to get user match requests")
		return nil, status.Errorf(codes.Internal, "failed to get user match requests: %v", err)
	}

	protoRequests := make([]*pb.MatchRequest, len(requests))
	for i, r := range requests {
		protoRequests[i] = s.matchRequestToProto(r)
	}

	return &pb.GetUserMatchRequestsResponse{
		MatchRequests: protoRequests,
	}, nil
}

func (s *MatchRequestServer) AcceptMatchRequest(ctx context.Context, req *pb.AcceptMatchRequestRequest) (*pb.AcceptMatchRequestResponse, error) {
	s.logger.WithFields(logrus.Fields{
		"request_id": req.RequestId,
		"user_id":    req.UserId,
	}).Info("Accepting match request via gRPC")

	matchReq, err := s.service.AcceptMatchRequest(ctx, req.RequestId, req.UserId)
	if err != nil {
		s.logger.WithError(err).Error("Failed to accept match request")
		if err.Error() == "user is not authorized to accept this request" {
			return nil, status.Errorf(codes.PermissionDenied, "user is not authorized to accept this request")
		}
		if err.Error() == "match request is not pending" {
			return nil, status.Errorf(codes.FailedPrecondition, "match request is not pending")
		}
		return nil, status.Errorf(codes.Internal, "failed to accept match request: %v", err)
	}

	return &pb.AcceptMatchRequestResponse{
		MatchRequest: s.matchRequestToProto(matchReq),
	}, nil
}

func (s *MatchRequestServer) RejectMatchRequest(ctx context.Context, req *pb.RejectMatchRequestRequest) (*pb.RejectMatchRequestResponse, error) {
	s.logger.WithFields(logrus.Fields{
		"request_id": req.RequestId,
		"user_id":    req.UserId,
	}).Info("Rejecting match request via gRPC")

	matchReq, err := s.service.RejectMatchRequest(ctx, req.RequestId, req.UserId)
	if err != nil {
		s.logger.WithError(err).Error("Failed to reject match request")
		if err.Error() == "user is not authorized to reject this request" {
			return nil, status.Errorf(codes.PermissionDenied, "user is not authorized to reject this request")
		}
		if err.Error() == "match request is not pending" {
			return nil, status.Errorf(codes.FailedPrecondition, "match request is not pending")
		}
		return nil, status.Errorf(codes.Internal, "failed to reject match request: %v", err)
	}

	return &pb.RejectMatchRequestResponse{
		MatchRequest: s.matchRequestToProto(matchReq),
	}, nil
}

func (s *MatchRequestServer) GetMatchRequest(ctx context.Context, req *pb.GetMatchRequestRequest) (*pb.GetMatchRequestResponse, error) {
	s.logger.WithField("request_id", req.RequestId).Info("Getting match request via gRPC")

	matchReq, err := s.service.GetMatchRequest(ctx, req.RequestId)
	if err != nil {
		s.logger.WithError(err).Error("Failed to get match request")
		if err.Error() == "match request not found" {
			return nil, status.Errorf(codes.NotFound, "match request not found")
		}
		return nil, status.Errorf(codes.Internal, "failed to get match request: %v", err)
	}

	return &pb.GetMatchRequestResponse{
		MatchRequest: s.matchRequestToProto(matchReq),
	}, nil
}

func (s *MatchRequestServer) CancelMatchRequest(ctx context.Context, req *pb.CancelMatchRequestRequest) (*pb.CancelMatchRequestResponse, error) {
	s.logger.WithFields(logrus.Fields{
		"request_id": req.RequestId,
		"user_id":    req.UserId,
	}).Info("Cancelling match request via gRPC")

	matchReq, err := s.service.CancelMatchRequest(ctx, req.RequestId, req.UserId)
	if err != nil {
		s.logger.WithError(err).Error("Failed to cancel match request")
		if err.Error() == "user is not authorized to cancel this request" {
			return nil, status.Errorf(codes.PermissionDenied, "user is not authorized to cancel this request")
		}
		if err.Error() == "only pending requests can be cancelled" {
			return nil, status.Errorf(codes.FailedPrecondition, "only pending requests can be cancelled")
		}
		return nil, status.Errorf(codes.Internal, "failed to cancel match request: %v", err)
	}

	return &pb.CancelMatchRequestResponse{
		MatchRequest: s.matchRequestToProto(matchReq),
	}, nil
}

func (s *MatchRequestServer) matchRequestToProto(req *models.MatchRequest) *pb.MatchRequest {
	return &pb.MatchRequest{
		Id:           req.ID,
		FromUserId:   req.FromUserID,
		ToUserId:     req.ToUserID,
		CommonTopics: req.CommonTopics,
		Similarity:   req.Similarity,
		Status:       req.Status,
		CreatedAt:    timestamppb.New(req.CreatedAt),
		UpdatedAt:    timestamppb.New(req.UpdatedAt),
	}
}
