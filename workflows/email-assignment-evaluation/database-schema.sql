-- Database Schema for Assignment Evaluations Workflow
-- PostgreSQL script to initialize evaluations table

CREATE TABLE IF NOT EXISTS evaluations (
  id SERIAL PRIMARY KEY,
  assignment_id VARCHAR(255) NOT NULL,
  extracted_text TEXT,
  correctness_score FLOAT,
  completeness_score FLOAT,
  grammar_score FLOAT,
  final_marks FLOAT,
  feedback TEXT,
  strengths TEXT[],
  weaknesses TEXT[],
  keywords_found TEXT[],
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_assignment_id ON evaluations(assignment_id);
CREATE INDEX IF NOT EXISTS idx_created_at ON evaluations(created_at);
