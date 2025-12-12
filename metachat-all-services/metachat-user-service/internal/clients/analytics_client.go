package clients

import (
	"context"
	"fmt"
	"time"

	"metachat/user-service/internal/service"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

type analyticsClient struct {
	conn *grpc.ClientConn
}

func NewAnalyticsClient(address string) (service.AnalyticsServiceClient, error) {
	if address == "" {
		return nil, nil
	}

	conn, err := grpc.NewClient(address, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		return nil, fmt.Errorf("failed to connect to analytics service: %w", err)
	}

	return &analyticsClient{conn: conn}, nil
}

func (c *analyticsClient) GetUserStatistics(ctx context.Context, userID string) (*service.UserStatistics, error) {
	if c == nil || c.conn == nil {
		return &service.UserStatistics{
			TotalDiaryEntries:     0,
			TotalMoodAnalyses:     0,
			TotalTokens:           0,
			DominantEmotion:       "",
			TopTopics:             []string{},
			ProfileCreatedAt:      time.Time{},
			LastPersonalityUpdate: time.Time{},
		}, nil
	}

	return nil, fmt.Errorf("analytics client not implemented - proto files need to be generated")
}

func (c *analyticsClient) Close() error {
	if c != nil && c.conn != nil {
		return c.conn.Close()
	}
	return nil
}

