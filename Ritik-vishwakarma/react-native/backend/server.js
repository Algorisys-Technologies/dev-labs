const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const cors = require('cors');
const app = express();
const port = 8080;

app.use(cors());
app.use(express.json());

// Initialize database
const db = new sqlite3.Database('./todos.db', (err) => {
  if (err) console.error(err.message);
  console.log('Connected to SQLite database');
});

// Create table
db.run(`CREATE TABLE IF NOT EXISTS todos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT,
  completed BOOLEAN DEFAULT 0
)`);

// CRUD Endpoints

// Get all todos
app.get('/todos', (req, res) => {
  db.all('SELECT * FROM todos', (err, rows) => {
    if (err) res.status(500).send(err);
    else res.json(rows);
  });
});

// Create todo
app.post('/todos', (req, res) => {
  const { title, description } = req.body;
  db.run(
    'INSERT INTO todos (title, description) VALUES (?, ?)',
    [title, description],
    function(err) {
      if (err) return res.status(500).send(err);
      res.json({ id: this.lastID });
    }
  );
});

// Update todo
app.put('/todos/:id', (req, res) => {
  const { title, description, completed } = req.body;
  db.run(
    `UPDATE todos 
     SET title = ?, description = ?, completed = ?
     WHERE id = ?`,
    [title, description, completed, req.params.id],
    (err) => {
      if (err) return res.status(500).send(err);
      res.json({ message: 'Updated successfully' });
    }
  );
});

// Delete todo
app.delete('/todos/:id', (req, res) => {
  db.run('DELETE FROM todos WHERE id = ?', req.params.id, (err) => {
    if (err) return res.status(500).send(err);
    res.json({ message: 'Deleted successfully' });
  });
});

app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});