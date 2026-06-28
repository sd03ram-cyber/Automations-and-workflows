# Setup & Configuration Guide

## Quick Start

### 1. Install Dependencies

```bash
# Tesseract OCR
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y tesseract-ocr

# macOS
brew install tesseract

# Windows: Download from https://github.com/UB-Mannheim/tesseract/wiki
```

### 2. Install & Run Ollama

```bash
# Download from https://ollama.ai
# Run locally
ollama serve

# In another terminal, pull a model
ollama pull mistral
# or for smaller models:
ollama pull neural-chat
ollama pull orca-mini
```

### 3. Setup PostgreSQL

```bash
# Install PostgreSQL
# Ubuntu/Debian
sudo apt-get install -y postgresql postgresql-contrib

# Start service
sudo systemctl start postgresql

# Create database
sudo -u postgres psql << 'SQL'
CREATE DATABASE assignments;
\c assignments

CREATE TABLE evaluations (
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
CREATE INDEX idx_assignment_id ON evaluations(assignment_id);
CREATE INDEX idx_created_at ON evaluations(created_at);
SQL
```

### 4. Start n8n

```bash
# Via Docker (recommended)
docker run -d \
  -p 5678:5678 \
  -v n8n_data:/home/node/.n8n \
  -e DB_TYPE=sqlite \
  -e WEBHOOK_URL=http://localhost:5678 \
  n8nio/n8n

# Or with npm
npm install -g n8n
n8n
```

Open http://localhost:5678

### 5. Import Workflow

1. In n8n: **Workflows** → **Create new** → **Import from file**
2. Select `Email_automation_CORRECTED.json`
3. Configure credentials:

#### PostgreSQL Credentials
- **Connection type:** PostgreSQL
- **Host:** localhost
- **Port:** 5432
- **Database:** assignments
- **User:** postgres
- **Password:** (your postgres password)

#### HTTP Request (Ollama)
Already configured to `http://localhost:11434/api/generate`
- No authentication needed (unless Ollama is behind proxy)

#### HTTP Request (Download File)
Keep as-is unless files are auth-protected

4. **Save** and **Activate**

### 6. Test the Workflow

```bash
# Get webhook URL from n8n (look at "Webhook Trigger" node)
# Should look like: http://localhost:5678/webhook/assignment-upload

curl -X POST http://localhost:5678/webhook/assignment-upload \
  -H "Content-Type: application/json" \
  -d '{
    "file_path": "https://example.com/sample_assignment.pdf",
    "assignment_name": "Cybersecurity Fundamentals",
    "subject": "Information Security"
  }'
```

---

## Troubleshooting

### Tesseract not found
```bash
# Check if installed
which tesseract

# If not found, add to PATH or specify full path in n8n:
# In "OCR Text Extraction" node, change command to:
/usr/local/bin/tesseract {{ $json.file_path }} stdout
# (adjust path based on your installation)
```

### Ollama connection refused
```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# If failed, start Ollama
ollama serve

# Check which model is loaded
ollama list
```

### PostgreSQL connection error
```bash
# Test PostgreSQL connection
psql -U postgres -h localhost -d assignments -c "SELECT 1;"

# If fails, check if service is running
sudo systemctl status postgresql

# Check logs
sudo tail -f /var/log/postgresql/postgresql-*.log
```

### File download fails
- Ensure `file_path` URL is publicly accessible
- Check if CORS is enabled on file server
- Try downloading manually: `curl {{ file_path }} -o test.pdf`

### OCR produces garbage text
- File might be corrupted or not actually a PDF
- Try with different file: `tesseract /path/to/file.pdf stdout`
- Consider using PyPDF for text extraction instead

### AI evaluation returns empty/null
- Check Ollama model is loaded: `ollama list`
- Test Ollama directly:
  ```bash
  curl -X POST http://localhost:11434/api/generate \
    -H "Content-Type: application/json" \
    -d '{
      "model": "mistral",
      "prompt": "Test prompt",
      "stream": false
    }'
  ```

---

## Performance Tips

### 1. Use Smaller Models for Speed
```bash
ollama pull orca-mini        # 3.3B params, ~2GB
ollama pull neural-chat      # 7B params, ~5GB
# Default: mistral (7B params, ~5GB)
```

### 2. Increase Ollama Memory
```bash
# Set environment variable before starting Ollama
export OLLAMA_MAX_LOADED_MODELS=1
ollama serve
```

### 3. Add Database Indexes
Already done in schema, but verify:
```sql
SELECT * FROM pg_indexes WHERE tablename = 'evaluations';
```

### 4. Batch Evaluations
For bulk processing:
```bash
# Create a loop workflow that processes multiple assignments
# Use "Loop" node with input array of file paths
```

---

## Production Deployment

### Switch to PostgreSQL Server
```bash
# Instead of localhost, use your server address
# Host: your-postgres-server.com
# Add SSL/TLS encryption
# Set up connection pooling (PgBouncer)
```

### Secure Webhook Endpoint
Add authentication header validation:
```javascript
// Add in a "Code" node before webhook trigger
if (!$json.headers['authorization']) {
  throw new Error('Unauthorized');
}

const token = $json.headers['authorization'].replace('Bearer ', '');
if (token !== process.env.WEBHOOK_SECRET) {
  throw new Error('Invalid token');
}

return $json;
```

### Environment Variables
```bash
# .env file for n8n
WEBHOOK_URL=https://your-domain.com
OLLAMA_ENDPOINT=http://ollama-container:11434
POSTGRES_HOST=postgres-container
POSTGRES_DB=assignments
POSTGRES_USER=app_user
POSTGRES_PASSWORD=secure_password_here
```

### Docker Compose Stack
```yaml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    ports:
      - "5678:5678"
    environment:
      DB_TYPE: postgres
      DB_POSTGRESDB_HOST: postgres
      DB_POSTGRESDB_DATABASE: n8n
      DB_POSTGRESDB_USER: n8n
      DB_POSTGRESDB_PASSWORD: n8n_password
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      - postgres
      - ollama

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_PASSWORD: postgres_password
      POSTGRES_DB: assignments
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql

  ollama:
    image: ollama/ollama:latest
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama

volumes:
  n8n_data:
  postgres_data:
  ollama_data:
```

Run with: `docker-compose up -d`

---

## Monitoring

### n8n Execution Logs
Check workflow executions in n8n UI → **Executions**

### PostgreSQL Monitoring
```sql
-- Check table size
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) 
FROM pg_tables 
WHERE tablename = 'evaluations';

-- Check slow queries
SELECT query, calls, total_time FROM pg_stat_statements 
ORDER BY total_time DESC LIMIT 10;

-- Monitor connections
SELECT datname, usename, application_name, state 
FROM pg_stat_activity;
```

### Ollama Logs
```bash
# Check if Ollama is responsive
curl http://localhost:11434/api/tags

# Monitor models loaded
watch 'ollama list'
```

---

## Next Steps

- [ ] Set up error notification (email on workflow failure)
- [ ] Add Slack integration for evaluation alerts
- [ ] Create dashboard to view evaluation history
- [ ] Implement user authentication for webhook
- [ ] Add support for batch file uploads
- [ ] Build API wrapper around n8n workflow
