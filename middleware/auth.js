const jwt = require('jsonwebtoken');

module.exports = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization || req.headers.Authorization;

    if (!authHeader) {
      return res.status(401).json({ message: 'No token provided' });
    }

    // Netwaye espas + retour ligne Thunder ka mete
    const cleaned = String(authHeader).replace(/\r?\n|\r/g, ' ').trim();

    // Sipòte: "Bearer token", oswa menm si gen plizyè espas
    const parts = cleaned.split(/\s+/);

    if (parts.length < 2 || parts[0].toLowerCase() !== 'bearer') {
      return res.status(401).json({ message: 'Token format invalid' });
    }

    // Rekonstwi token an si kliyan an te kase li sou plizyè liy/espas
    const token = parts.slice(1).join('');

    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    req.user = decoded;
    next();
  } catch (err) {
    console.error('JWT error:', err.message);
    return res.status(401).json({
      message: 'Invalid or expired token',
      error: err.message
    });
  }
};