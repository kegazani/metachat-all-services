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

