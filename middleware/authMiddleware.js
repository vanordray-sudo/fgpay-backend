const jwt = require('jsonwebtoken');

const authMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return res.status(401).json({
      success: false,
      message: 'Token manquant',
    });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
req.userId = decoded.id || decoded.userId;
 req.user = decoded;

    console.log('DECODED:', decoded);

    // 🔥 SA SE FIX LA
   

    console.log('REQ USER ID:', req.userId);

    next();
  } catch (err) {
    return res.status(401).json({
      success: false,
      message: 'Token invalid',
    });
  }
};

module.exports = authMiddleware;

