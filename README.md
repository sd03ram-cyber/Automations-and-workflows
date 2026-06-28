# Automations & Workflows

A collection of n8n automation workflows for ABS Technologies.

## Workflows

### Email Automation / Assignment Evaluation Workflow

**Purpose:** Automated student assignment evaluation pipeline that extracts text from uploaded documents, evaluates them using local LLMs, scores them across multiple criteria, and stores results in a database.

**Trigger:** Webhook endpoint at `/assignment-upload`

#### Workflow Steps

1. **Webhook Trigger** (`n8n-nodes-base.webhook`)
   - Listens for POST requests to `/assignment-upload`
   - Expected payload: `file_path`, `assignment_name`, `subject`

2. **Download File** (`n8n-nodes-base.httpRequest`)
   - Downloads the assignment file from the provided `file_path`
   - Acts as intermediary between external storage and processing pipeline

3. **OCR Text Extraction** (`n8n-nodes-base.executeCommand`)
   - Runs Tesseract OCR on the downloaded file
   - Extracts raw text content for analysis
   - **Requires:** Tesseract installed and in system PATH

4. **Prepare AI Prompt** (`n8n-nodes-base.code`)
   - Constructs a structured JSON prompt for the AI evaluator
   - Includes assignment metadata (topic, subject) and extracted text
   - Requests evaluation across 7 dimensions:
     - Correctness score (0-10)
     - Completeness score (0-10)
     - Grammar score (0-10)
     - Constructive feedback
     - Strengths (list)
     - Weaknesses (list)
     - Keywords found (list)

5. **Call Ollama AI** (`n8n-nodes-base.httpRequest`)
   - Sends evaluation prompt to local Ollama instance
   - Endpoint: `http://localhost:11434/api/generate`
   - **Requires:** Ollama running locally with a capable model

6. **Parse AI Response** (`n8n-nodes-base.code`)
   - Extracts and normalizes AI response into structured JSON
   - Defaults missing values to prevent downstream errors
   - Returns: scores, feedback, strengths, weaknesses, keywords

7. **Calculate Final Marks** (`n8n-nodes-base.code`)
   - Computes three individual scores into a final mark
   - Formula: `(correctness + completeness + grammar) / 3`
   - Rounds to 2 decimal places
   - Outputs comprehensive evaluation object

8. **Store in Database** (`n8n-nodes-base.postgres`)
   - Inserts evaluation results into PostgreSQL `evaluations` table
   - Stores all scoring data, feedback, and metadata
   - **Requires:** PostgreSQL running with proper schema

9. **Return Response** (`n8n-nodes-base.respondToWebhook`)
   - Sends evaluation results back to webhook caller as HTTP response

---

## Issues & Limitations

### Critical
- **Broken workflow connections:** Nodes 1-4 have missing connection definitions. Only the AI processing chain (4→5→6→7) and database flow (7→8→9) are connected.
- **Ollama request body missing:** The HTTP POST to Ollama has no body defined. The prompt won't be sent.
- **No error handling:** No catch nodes. Any step failure crashes the entire workflow.

### Functional
- **Local-only dependencies:** 
  - Tesseract must be installed on the host
  - Ollama must run on `localhost:11434`
  - PostgreSQL must be accessible locally
  - Won't work in distributed/cloud environments without refactoring

- **Hardcoded endpoints:** All service URLs are hardcoded. Environment variables needed for flexibility.

- **Database schema undefined:** No SQL schema provided for the `evaluations` table. Manual setup required.

- **Model unspecified:** No model name provided to Ollama. Behavior depends on Ollama's default model.

### Missing Features
- No input validation on webhook payload
- No retry logic for network failures
- No logging beyond n8n's default
- No authentication on webhook endpoint (security risk)
- No pagination/streaming for large documents

---

## Setup Instructions

### Prerequisites
- **n8n** v1.0+ (running locally)
- **Tesseract OCR** (for text extraction)
  ```bash
  # Ubuntu/Debian
  sudo apt-get install tesseract-ocr
  
  # macOS
  brew install tesseract
  ```
- **Ollama** (for AI evaluation)
  ```bash
  # Download from https://ollama.ai
  # Run: ollama serve
  # Pull a model: ollama pull mistral (or similar)
  ```
- **PostgreSQL** (for results storage)
  ```bash
  # Create database and table
  psql -U postgres -c "CREATE DATABASE assignments;"
  psql -U postgres -d assignments << 'SQL'
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
  SQL
  ```

### Import Workflow
1. Open n8n UI → **Workflows** → **Create new**
2. Click **Import from file** → select `Email_automation.json`
3. Fix broken connections (connect nodes 1→2→3→4 manually)
4. Update node credentials:
   - **Download File:** Add HTTP auth if needed
   - **Call Ollama AI:** Add request body: `{"prompt": "{{ $json.prompt }}", "stream": false}`
   - **Store in Database:** Add PostgreSQL credentials
5. Test with sample webhook POST

### Configuration
Set these as n8n environment variables or in node credentials:
```
TESSERACT_PATH=/usr/bin/tesseract
OLLAMA_ENDPOINT=http://localhost:11434
OLLAMA_MODEL=mistral
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=assignments
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_password
```

---

## Usage Example

**Webhook Request:**
```bash
curl -X POST http://localhost:5678/webhook/assignment-upload \
  -H "Content-Type: application/json" \
  -d '{
    "file_path": "https://example.com/assignment.pdf",
    "assignment_name": "Cybersecurity Basics",
    "subject": "Network Security"
  }'
```

**Response:**
```json
{
  "marks": {
    "correctness": 8,
    "completeness": 7,
    "grammar": 9,
    "final": 8.0
  },
  "feedback": "Well-structured response with minor gaps in advanced concepts.",
  "strengths": ["Clear explanation", "Good examples"],
  "weaknesses": ["Missing edge cases"],
  "keywords_found": ["encryption", "authentication", "firewall"]
}
```

---

## Roadmap

- [ ] Fix workflow connections
- [ ] Add error handling and retry logic
- [ ] Support environment variables for all endpoints
- [ ] Add webhook authentication (API key)
- [ ] Input validation for payload
- [ ] Support multiple file formats (PDF, DOCX, images, etc.)
- [ ] Streaming responses for large evaluations
- [ ] Dashboard for viewing evaluation history
- [ ] Batch evaluation mode
- [ ] Custom evaluation rubrics

---

## Author
ABS Technologies (Analyse, Build, Secure)

## License
MIT
