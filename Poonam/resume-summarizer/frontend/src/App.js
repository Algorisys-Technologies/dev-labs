import React from 'react';
import './App.css';
import ResumeUploader from './ResumeUploader';

function App() {
  return (
    <div className="app-wrapper">
      <div className="card">
        <h1>Resume Summarizer</h1>
        <p className="subtitle">Upload a resume to get a quick AI-generated summary</p>
        <ResumeUploader />
      </div>
    </div>
  );
}

export default App;
