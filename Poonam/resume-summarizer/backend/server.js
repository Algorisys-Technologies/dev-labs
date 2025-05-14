import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import apiRoutes from './routes/api.js';  // Import API route file

// Configure dotenv to load environment variables
dotenv.config();

// Log the API key to check if it's loaded correctly (for debugging purposes)
console.log('OPENAI_API_KEY:', process.env.GEMINI_API_KEY);  // This should print your API key

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

// Mount the API route at /api
app.use('/api', apiRoutes);

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
