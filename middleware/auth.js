const jwt = require('jsonwebtoken');

module.exports = (req, res, next) => {
const authHeader = req.headers['authorization'];

if (!authHeader) {
  return res.status(401).json({ message: 'Token manquant' });
}

const parts = authHeader.split(' ');
const token = parts.length === 2 ? parts[1] : null;

if (!token) {
  return res.status(401).json({ message: 'Token manquant ou mal formé' });
}

try {
const decoded = jwt.verify(token, process.env.JWT_SECRET);

console.log('DECODED:', decoded);

// 🔥 FIX FINAL
req.userId = decoded.id || decoded.userId;

console.log('REQ.USERID:', req.userId);

next();  
  
} catch (err) {
  console.log('JWT ERROR:', err.message);
  console.log('JWT SECRET:', process.env.JWT_SECRET ? 'OK' : 'MISSING');
  return res.status(403).json({ message: 'Token invalide' });
}
}