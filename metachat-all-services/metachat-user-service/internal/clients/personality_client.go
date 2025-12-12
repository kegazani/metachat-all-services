package clients

import (
	"context"
	"fmt"

	"metachat/user-service/internal/service"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

type personalityClient struct {
	conn *grpc.ClientConn
}

func NewPersonalityClient(address string) (service.PersonalityServiceClient, error) {
	if address == "" {
		return nil, nil
	}

	conn, err := grpc.NewClient(address, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		return nil, fmt.Errorf("failed to connect to personality service: %w", err)
	}

	return &personalityClient{conn: conn}, nil
}

func (c *personalityClient) GetProfileProgress(ctx context.Context, userID string) (*service.ProfileProgress, error) {
	if c == nil || c.conn == nil {
		return &service.ProfileProgress{
			TokensAnalyzed:          0,
			TokensRequiredForFirst:  50,
			TokensRequiredForRecalc: 100,
			DaysSinceLastCalc:       0,
			DaysUntilRecalc:         0,
			IsFirstCalculation:      true,
			ProgressPercentage:      0.0,
		}, nil
	}

	return nil, fmt.Errorf("personality client not implemented - proto files need to be generated")
}

func (c *personalityClient) Close() error {
	if c != nil && c.conn != nil {
		return c.conn.Close()
	}
	return nil
}

