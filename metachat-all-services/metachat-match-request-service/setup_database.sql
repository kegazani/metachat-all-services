CREATE DATABASE metachat;

\c metachat;

CREATE TABLE IF NOT EXISTS match_requests (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_match_requests_user_id ON match_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_match_requests_status ON match_requests(status);

