const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../db');

const router = express.Router();

/**
 * POST /api/auth/login
 * Body: { phone, password }
 */
router.post('/login', async (req, res) => {
  try {
    console.log('LOGIN BODY:', req.body);

    const { phone, password } = req.body;

    if (!phone || !password) {
      return res.status(400).json({
        success: false,
        message: 'Phone et password requis',
      });
    }

    // 🔎 Cherche user
    const result = await pool.query(
      'SELECT id, phone, password FROM users WHERE phone = $1',
      [phone]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Utilisateur introuvable',
      });
    }

    const user = result.rows[0];

    console.log('USER DB:', user);

    // 🔥 TEMPORAIRE (plain password)
    const passwordOk = password === user.password;

    if (!passwordOk) {
      return res.status(401).json({
        success: false,
        message: 'Mot de passe incorrect',
      });
    }

    // 🔐 TOKEN
    const token = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET || 'secret123',
      { expiresIn: '7d' }
    );

    return res.json({
      success: true,
      token,
      user: {
        id: user.id,
        phone: user.phone,
      },
    });

  } catch (error) {
    console.error('LOGIN ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Erreur serveur login',
      error: error.message,
    });
  }
});
/**
 * GET /api/auth/me
 * Header: Authorization: Bearer TOKEN
 */
router.get('/me', async (req, res) => {
  return res.json({
    success: true,
    message: 'Utilisez le middleware auth sur cette route si besoin',
  });
});

module.exports = router;