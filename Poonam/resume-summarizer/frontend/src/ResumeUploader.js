// src/ResumeUploader.js
import React, { useState } from 'react';
import axios from 'axios';

function ResumeUploader() {
  const [file, setFile] = useState(null);
  const [summary, setSummary] = useState('');
  const [loading, setLoading] = useState(false);

  const handleFileChange = (e) => {
    setFile(e.target.files[0]);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!file) return alert('Please upload a file');

    const formData = new FormData();
    formData.append('resume', file); // "resume" must match the backend field name

    setLoading(true);
    try {
      const res = await axios.post('http://localhost:5000/api/upload', formData);
      setSummary(res.data.summary);
    } catch (err) {
      console.error('Upload failed:', err);
      alert('Upload failed. Check console for details.');
    }
    setLoading(false);
  };

  return (
    <div style={{ padding: '2rem' }}>
      <h2>Upload Resume (PDF)</h2>
      <form onSubmit={handleSubmit}>
        <input type="file" accept="application/pdf" onChange={handleFileChange} />
        <button type="submit" disabled={loading}>
          {loading ? 'Uploading...' : 'Upload'}
        </button>
      </form>

      {summary && (
        <div style={{ marginTop: '2rem' }}>
          <h3>Resume Summary</h3>
          <p>{summary}</p>
        </div>
      )}
    </div>
  );
}

export default ResumeUploader;
