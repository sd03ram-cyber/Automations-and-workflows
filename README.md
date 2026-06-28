# Automations & Workflows

A central repository for storing and managing n8n automation workflows, database schemas, and helper scripts used by ABS Technologies.

---

## 📂 Repository Structure

Workflows are organized into self-contained subdirectories within the `workflows/` directory. Each workflow folder contains:
*   Its n8n JSON representation
*   A workflow-specific `README.md` containing requirements and setup instructions
*   Any supporting files (e.g., SQL schemas, scripts, or compose files)

```
Automations-and-workflows/
├── README.md                              # Root repository index (this file)
└── workflows/
    └── [workflow-name]/                   # Workflow folder
        ├── README.md                      # Setup & usage instructions
        ├── [workflow-name].json           # n8n workflow export
        └── [supporting-files]             # SQL scripts, configurations, etc.
```

---

## 🤖 Available Workflows

| Workflow Name | Path | Description | Key Services |
| :--- | :--- | :--- | :--- |
| **Email Automation & Assignment Evaluation** | [`workflows/email-assignment-evaluation`](file:///c:/Users/Windows/Documents/ai%20automations%20github/workflows/email-assignment-evaluation) | Automated assignment evaluation extracting text via OCR, grading via Ollama LLM, and saving results. | n8n, Ollama, PostgreSQL, Tesseract |

---

## 🛠️ How to Add a New Workflow

To contribute a new workflow to this repository, please follow these structure guidelines:

1. **Create a new folder** under `workflows/` using a descriptive kebab-case name:
   ```bash
   mkdir workflows/my-new-workflow
   ```
2. **Export your n8n workflow** as a JSON file and save it in that directory as `[workflow-name].json`.
3. **Include supporting assets** (e.g., if it uses database tables, export the schema to a `.sql` file in the same directory).
4. **Write a README.md** inside the workflow directory describing:
   *   The purpose and logic of the workflow (using a diagram if possible)
   *   Step-by-step installation instructions for external dependencies
   *   Configuration parameters or environment variables needed
   *   A sample webhook request/response or trigger payload
5. **Update this root README.md** table above to include the new workflow.

---

## 📄 License
This repository is licensed under the MIT License.
