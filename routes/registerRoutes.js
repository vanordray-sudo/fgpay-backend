router.post('/register', async (req, res) => {
  try {
    const { fullname, phone, email, password } = req.body || {};

    if (!fullname || !phone || !password) {
      return res.status(400).json({
        success: false,
        message: 'Nom, téléphone et mot de passe requis',
      });
    }

    const existing = await pool.query(
      `SELECT id FROM users WHERE phone = $1 LIMIT 1`,
      [phone]
    );

    if (existing.rows.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Ce numéro existe déjà',
      });
    }

    const auth = require('../middlewares/auth');

router.get('/my-subscription', auth, async (req, res) => {
  res.json({
    success: true,
    userId: req.userId,
  });
});
    
    const hashedPassword = await bcrypt.hash(password, 10);

    const result = await pool.query(
      `
      INSERT INTO users (fullname, phone, email, password, balance, role)
      VALUES ($1, $2, $3, $4, 0, 'user')
      RETURNING id, fullname, phone, email, balance, role
      `,
      [fullname, phone, email || null, hashedPassword]
    );

    return res.json({
      success: true,
      message: 'Utilisateur créé avec succès',
      user: result.rows[0],
    });
  } catch (error) {
    console.error('Erreur POST /api/auth/register:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur register',
    });
  }
});