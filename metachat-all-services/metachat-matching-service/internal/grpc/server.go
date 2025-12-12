package grpc

import (
	"context"
	"time"

	"metachat/matching-service/internal/repository"
	"metachat/matching-service/internal/service"

	"github.com/sirupsen/logrus"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"

	pb "github.com/kegazani/metachat-proto/matching"
)

type MatchingServer struct {
	pb.UnimplementedMatchingServiceServer
	matchingService service.MatchingService
	logger          *logrus.Logger
}

func NewMatchingServer(svc service.MatchingService, logger *logrus.Logger) *MatchingServer {
	return &MatchingServer{
		matchingService: svc,
		logger:          logger,
	}
}

func (s *MatchingServer) GetCommonTopics(ctx context.Context, req *pb.GetCommonTopicsRequest) (*pb.GetCommonTopicsResponse, error) {
	s.logger.WithFields(logrus.Fields{
		"user_id1": req.UserId1,
		"user_id2": req.UserId2,
	}).Info("Getting common topics via gRPC")

	topics, err := s.matchingService.GetCommonTopics(ctx, req.UserId1, req.UserId2)
	if err != nil {
		s.logger.WithError(err).Error("Failed to get common topics")
		return nil, status.Errorf(codes.Internal, "failed to get common topics: %v", err)
	}

	return &pb.GetCommonTopicsResponse{
		CommonTopics: topics,
	}, nil
}

func (s *MatchingServer) FindSimilarUsers(ctx context.Context, req *pb.FindSimilarUsersRequest) (*pb.FindSimilarUsersResponse, error) {
	s.logger.WithField("user_id", req.UserId).Info("Finding similar users via gRPC")

	limit := int(req.Limit)
	if limit <= 0 {
		limit = 10
	}

	matches, err := s.matchingService.FindSimilarUsers(ctx, req.UserId, limit)
	if err != nil {
		s.logger.WithError(err).Error("Failed to find similar users")
		return nil, status.Errorf(codes.Internal, "failed to find similar users: %v", err)
	}

	protoMatches := make([]*pb.UserMatch, len(matches))
	for i, m := range matches {
		protoMatches[i] = s.userMatchToProto(m)
	}

	return &pb.FindSimilarUsersResponse{
		Matches: protoMatches,
	}, nil
}

func (s *MatchingServer) CalculateUserSimilarity(ctx context.Context, req *pb.CalculateUserSimilarityRequest) (*pb.CalculateUserSimilarityResponse, error) {
	s.logger.WithFields(logrus.Fields{
		"user_id1": req.UserId1,
		"user_id2": req.UserId2,
	}).Info("Calculating user similarity via gRPC")

	similarity, err := s.matchingService.CalculateUserSimilarity(ctx, req.UserId1, req.UserId2)
	if err != nil {
		s.logger.WithError(err).Error("Failed to calculate user similarity")
		return nil, status.Errorf(codes.Internal, "failed to calculate user similarity: %v", err)
	}

	return &pb.CalculateUserSimilarityResponse{
		Similarity: similarity,
	}, nil
}

func (s *MatchingServer) GetUserMatches(ctx context.Context, req *pb.GetUserMatchesRequest) (*pb.GetUserMatchesResponse, error) {
	s.logger.WithField("user_id", req.UserId).Info("Getting user matches via gRPC")

	matches, err := s.matchingService.GetUserMatches(ctx, req.UserId)
	if err != nil {
		s.logger.WithError(err).Error("Failed to get user matches")
		return nil, status.Errorf(codes.Internal, "failed to get user matches: %v", err)
	}

	protoMatches := make([]*pb.UserMatch, len(matches))
	for i, m := range matches {
		protoMatches[i] = s.userMatchToProto(m)
	}

	return &pb.GetUserMatchesResponse{
		Matches: protoMatches,
	}, nil
}

func (s *MatchingServer) GetUserPortrait(ctx context.Context, req *pb.GetUserPortraitRequest) (*pb.GetUserPortraitResponse, error) {
	return nil, status.Errorf(codes.Unimplemented, "method GetUserPortrait not implemented")
}

func (s *MatchingServer) SaveUserMatch(ctx context.Context, req *pb.SaveUserMatchRequest) (*pb.SaveUserMatchResponse, error) {
	return nil, status.Errorf(codes.Unimplemented, "method SaveUserMatch not implemented")
}

func (s *MatchingServer) UpdateUserPortrait(ctx context.Context, req *pb.UpdateUserPortraitRequest) (*pb.UpdateUserPortraitResponse, error) {
	return nil, status.Errorf(codes.Unimplemented, "method UpdateUserPortrait not implemented")
}

func (s *MatchingServer) userMatchToProto(match *repository.UserMatch) *pb.UserMatch {
	protoMatch := &pb.UserMatch{
		UserId1:    match.UserID1,
		UserId2:    match.UserID2,
		Similarity: match.Similarity,
		CommonTags: match.CommonTags,
	}

	if match.CreatedAt != "" {
		if t, err := time.Parse(time.RFC3339, match.CreatedAt); err == nil {
			protoMatch.CreatedAt = timestamppb.New(t)
		}
	}

	return protoMatch
}

