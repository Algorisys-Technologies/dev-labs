Resume Summarizer

A full-stack application that allows users to upload a PDF resume and receive an AI-generated summary using the Gemini (Google Generative AI) API.

Features

- Upload a PDF resume from the frontend.
- Extract text content from the PDF using a backend utility.
- Generate a summary of the resume via the Gemini API.
- Display the summary on the frontend.

Tech Stack

- Frontend: React.js
- Backend: Node.js, Express.js
- PDF Parsing: `pdf-parse`
- AI Model: Gemini API (`@google/generative-ai`)


Setup Instructions

- Backend Setup:
   cd backend
   npm install

-Create a .env file in the backend directory with your Gemini API key:
GEMINI_API_KEY=your_gemini_api_key_here

-Start the backend server: node server.js
The backend will run at: http://localhost:5000

- Frontend Setup
    cd frontend
    npm install

- Start the frontend server: npm start
The frontend will run at: http://localhost:3000


- Clone the Repository

```bash
git clone https://github.com/your-username/resume-summarizer.git
cd resume-summarizer
