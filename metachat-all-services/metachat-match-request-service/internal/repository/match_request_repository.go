package repository

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"metachat/match-request-service/internal/models"

	"github.com/lib/pq"
)

type MatchRequestRepository interface {
	CreateMatchRequest(ctx context.Context, req *models.MatchRequest) error
	GetMatchRequestByID(ctx context.Context, id string) (*models.MatchRequest, error)
	GetUserMatchRequests(ctx context.Context, userID string, status string) ([]*models.MatchRequest, error)
	UpdateMatchRequestStatus(ctx context.Context, id string, status string) error
	DeleteMatchRequest(ctx context.Context, id string) error
	InitializeTables() error
}

type matchRequestRepository struct {
	db *sql.DB
}

func NewMatchRequestRepository(db *sql.DB) MatchRequestRepository {
	return &matchRequestRepository{
		db: db,
	}
}

func (r *matchRequestRepository) InitializeTables() error {
	query := `
	CREATE TABLE IF NOT EXISTS match_requests (
		id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
		from_user_id UUID NOT NULL,
		to_user_id UUID NOT NULL,
		common_topics TEXT[],
		similarity FLOAT,
		status VARCHAR(20) NOT NULL DEFAULT 'pending',
		created_at TIMESTAMP NOT NULL DEFAULT NOW(),
		updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
		UNIQUE(from_user_id, to_user_id, status)
	);

	CREATE INDEX IF NOT EXISTS idx_match_requests_from_user ON match_requests(from_user_id);
	CREATE INDEX IF NOT EXISTS idx_match_requests_to_user ON match_requests(to_user_id);
	CREATE INDEX IF NOT EXISTS idx_match_requests_status ON match_requests(status);
	`

	_, err := r.db.Exec(query)
	return err
}

func (r *matchRequestRepository) CreateMatchRequest(ctx context.Context, req *models.MatchRequest) error {
	query := `
	INSERT INTO match_requests (id, from_user_id, to_user_id, common_topics, similarity, status, created_at, updated_at)
	VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	ON CONFLICT (from_user_id, to_user_id, status) DO NOTHING
	RETURNING id, created_at, updated_at
	`

	var id string
	var createdAt, updatedAt time.Time
	err := r.db.QueryRowContext(ctx, query,
		req.ID, req.FromUserID, req.ToUserID, pq.Array(req.CommonTopics),
		req.Similarity, req.Status, req.CreatedAt, req.UpdatedAt,
	).Scan(&id, &createdAt, &updatedAt)

	if err != nil {
		if err == sql.ErrNoRows {
			return fmt.Errorf("match request already exists")
		}
		return err
	}

	req.ID = id
	req.CreatedAt = createdAt
	req.UpdatedAt = updatedAt
	return nil
}

func (r *matchRequestRepository) GetMatchRequestByID(ctx context.Context, id string) (*models.MatchRequest, error) {
	query := `
	SELECT id, from_user_id, to_user_id, common_topics, similarity, status, created_at, updated_at
	FROM match_requests
	WHERE id = $1
	`

	var req models.MatchRequest
	var topics []string
	err := r.db.QueryRowContext(ctx, query, id).Scan(
		&req.ID, &req.FromUserID, &req.ToUserID, pq.Array(&topics),
		&req.Similarity, &req.Status, &req.CreatedAt, &req.UpdatedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("match request not found")
		}
		return nil, err
	}

	req.CommonTopics = topics
	return &req, nil
}

func (r *matchRequestRepository) GetUserMatchRequests(ctx context.Context, userID string, status string) ([]*models.MatchRequest, error) {
	var query string
	var args []interface{}

	if status != "" {
		query = `
		SELECT id, from_user_id, to_user_id, common_topics, similarity, status, created_at, updated_at
		FROM match_requests
		WHERE (from_user_id = $1 OR to_user_id = $1) AND status = $2
		ORDER BY created_at DESC
		`
		args = []interface{}{userID, status}
	} else {
		query = `
		SELECT id, from_user_id, to_user_id, common_topics, similarity, status, created_at, updated_at
		FROM match_requests
		WHERE from_user_id = $1 OR to_user_id = $1
		ORDER BY created_at DESC
		`
		args = []interface{}{userID}
	}

	rows, err := r.db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var requests []*models.MatchRequest
	for rows.Next() {
		var req models.MatchRequest
		var topics []string
		err := rows.Scan(
			&req.ID, &req.FromUserID, &req.ToUserID, pq.Array(&topics),
			&req.Similarity, &req.Status, &req.CreatedAt, &req.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		req.CommonTopics = topics
		requests = append(requests, &req)
	}

	return requests, rows.Err()
}

func (r *matchRequestRepository) UpdateMatchRequestStatus(ctx context.Context, id string, status string) error {
	query := `
	UPDATE match_requests
	SET status = $1, updated_at = NOW()
	WHERE id = $2
	`

	result, err := r.db.ExecContext(ctx, query, status, id)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return fmt.Errorf("match request not found")
	}

	return nil
}

func (r *matchRequestRepository) DeleteMatchRequest(ctx context.Context, id string) error {
	query := `DELETE FROM match_requests WHERE id = $1`

	result, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return fmt.Errorf("match request not found")
	}

	return nil
}

