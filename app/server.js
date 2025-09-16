const express = require('express');
const mysql = require('mysql2/promise');
const app = express();
const PORT = parseInt(process.env.PORT || '3000', 10);
const DB_HOST = process.env.DB_HOST || '127.0.0.1';
const DB_USER = process.env.DB_USER || 'admin';
const DB_PASSWORD = process.env.DB_PASSWORD || '';
const DB_NAME = process.env.DB_NAME || 'appdb';
async function ensureSchema() {
  const conn = await mysql.createConnection({host: DB_HOST, user: DB_USER, password: DB_PASSWORD});
  await conn.query(`CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\``);
  await conn.end();
}
app.get('/health', async (req, res) => {
  try {
    const conn = await mysql.createConnection({host: DB_HOST, user: DB_USER, password: DB_PASSWORD});
    const [rows] = await conn.query('SELECT 1 AS ok');
    await conn.end();
    res.json({ ok: rows[0].ok === 1 });
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});
app.listen(PORT, async () => {
  try { await ensureSchema(); } catch (e) { console.error('Schema init failed:', e.message); }
  console.log(`Listening on :${PORT}`);
});
