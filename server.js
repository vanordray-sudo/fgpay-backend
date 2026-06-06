require('dotenv').config();

const cors = require('cors');
const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const path = require('path');

const pool = require('./db');
const walletRoutes = require('./routes/walletRoutes');
const paypalRoutes = require('./routes/paypalRoutes');
const esimRoutes = require('./routes/esimRoutes');
const stripeRoutes = require('./routes/stripeRoutes');
const channelRoutes = require('./routes/channelRoutes');
const internetRoutes = require('./routes/internetRoutes');
const authRoutes = require('./routes/authRoutes');
const testRoutes = require('./routes/testRoutes');
const labRoutes = require('./routes/labRoutes');
const adminRoutes = require('./routes/adminRoutes');
const healthRoutes = require('./routes/healthRoutes');
const referralRoutes = require('./routes/referralRoutes');
const appointmentRoutes = require('./routes/appointmentRoutes');
const prescriptionRoutes =require('./routes/prescriptionRoutes');
const medicalRecordRoutes = require('./routes/medicalRecordRoutes');
const doctorAvailabilityRoutes = require('./routes/doctorAvailabilityRoutes');
const professionalRoutes = require('./routes/professionalRoutes');
const Stripe = require('stripe');
// const admin = require('./serviceAccountkey');






const app = express();

const PORT = process.env.PORT || 5000;
const JWT_SECRET = process.env.JWT_SECRET || 'secret';
const router = express.Router();
const stripe = Stripe(process.env.STRIPE_SECRET_KEY);

// =========================
// MIDDLEWARES
// =========================
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use( '/uploads',express.static(path.join(__dirname, 'uploads')));
app.use('/api/health', healthRoutes);

app.use('/api/subscription', router);
app.use('/api/wallet', walletRoutes);
app.use('/api/test', testRoutes);
app.use('/api/channels', channelRoutes);
app.use('/api/internet', internetRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/esim', esimRoutes);
app.use('/api/labs', labRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/referrals', referralRoutes);
app.use('/api/appointments', appointmentRoutes);
app.use( '/api/prescriptions',prescriptionRoutes,);
app.use('/api/medical-records', medicalRecordRoutes);
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/api/referrals', referralRoutes);
app.use('/api/doctor-availabilities', doctorAvailabilityRoutes);
app.use('/api/health', prescriptionRoutes);
app.use('/api/professionals',professionalRoutes);
app.use('/api/health', healthRoutes);



app.listen(PORT, () => {
  console.log(`Serveur démarré sur http://localhost:${PORT}`);
});

// =========================
// DEBUG / STARTUP LOGS
// =========================
console.log('STRIPE KEY =', process.env.STRIPE_SECRET_KEY ? 'OK' : 'MISSING');

pool.query('SELECT NOW()')
  .then(() => console.log('DB CONNECTED OK'))
  .catch((err) => console.error('DB ERROR:', err.message));

pool.query('SELECT * FROM users')
  .then((res) => console.log('USERS OK:', res.rows.length))
  .catch((err) => console.error('ERROR USERS:', err.message));

// =========================
// AUTH HELPERS
// =========================
function auth(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'Token manquant',
    });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.userId = decoded.id;
    req.user = decoded;
    next();
  } catch (e) {
    return res.status(401).json({
      success: false,
      message: 'Token invalide',
    });
  }
}

const authMiddleware = auth;

app.get('/test-upload', (req, res) => {
  res.sendFile(
    path.resolve(__dirname, 'uploads', 'medical-results', 'test.pdf')
  );
});

// =========================
// BASIC ROUTE
// =========================
app.get('/', (req, res) => {
  res.send(`FGPay API running on http://localhost:${PORT}`);
});


// =========================
// EXTERNAL FEATURE ROUTES
// =========================
app.use('/api/stripe', stripeRoutes);
app.use('/api/esim', esimRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/paypal', paypalRoutes);
app.use('/api/services', walletRoutes);


// =========================
// LOGIN
// =========================
app.post('/login', async (req, res) => {
  try {
    const { phone, password } = req.body || {};

    if (!phone || !password) {
      return res.status(400).json({
        success: false,
        message: 'Téléphone et mot de passe requis',
      });
    }

    const result = await pool.query(
      'SELECT * FROM users WHERE phone = $1 LIMIT 1',
      [phone]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Utilisateur introuvable',
      });
    }

    const user = result.rows[0];

    const passwordOk =
      user.password === password ||
      bcrypt.compareSync(password, user.password);

    if (!passwordOk) {
      return res.status(401).json({
        success: false,
        message: 'Mot de passe incorrect',
      });
    }

   const token = jwt.sign(
  { id: user.id }, // 🔥 pa mete userId, mete id
  process.env.JWT_SECRET,
  { expiresIn: '7d' }
);


console.log('LOGIN USER RESPONSE:', {
  id: user.id,
  phone: user.phone,
  role: user.role,
  health_role: user.health_role,
  full_name: user.full_name,
  professional_status: user.professional_status,
is_verified_professional: user.is_verified_professional,
});

    return res.json({
      success: true,
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        balance: user.balance,
        role: user.role,
        full_name: user.full_name,
        health_role: user.health_role,
        professional_status: user.professional_status,
        is_verified_professional: user.is_verified_professional,
      },
    });
  } catch (e) {
    return res.status(500).json({
      success: false,
      message: `Erreur login: ${e.message}`,
    });
  }
});

app.get('/api/health/professionals/pending', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        id,
        full_name,
        phone,
        email,
        health_role,
        created_at
      FROM users
      WHERE health_role IS NOT NULL
      AND approved = false
      ORDER BY created_at DESC
    `);

    res.json(result.rows);
  } catch (e) {
    res.status(500).json({
      message: e.message,
    });
  }
});

app.put('/api/health/professionals/:id/approve', async (req, res) => {
  try {
    const { id } = req.params;

    await pool.query(`
      UPDATE users
      SET
        professional_status = 'approved',
        is_verified_professional = true,
        validated_by_admin = true,
        verified_at = NOW()
      WHERE id = $1
    `, [id]);

    await pool.query(
      `
      INSERT INTO notifications
      (user_id, title, message, type)
      VALUES ($1, $2, $3, $4)
      `,
      [
        id,
        'Profil approuvé',
        'Votre profil professionnel a été approuvé par FG Santé.',
        'professional_approved'
      ]
    );

    console.log('APPROVE ID:', id);
    console.log('NOTIFICATION SENT TO USER:', id);

    res.json({
      success: true,
      message: 'Professionnel approuvé'
    });

  } catch (e) {
    res.status(500).json({
      success: false,
      message: e.message,
    });
  }
});

app.put('/api/health/professionals/:id/reject', async (req, res) => {
  try {
    const { id } = req.params;

   await pool.query(`
  UPDATE users
  SET
    professional_status = 'rejected',
    is_verified_professional = false
  WHERE id = $1
`, [id]);

    res.json({
      success: true,
      message: 'Professionnel rejeté'
    });

  } catch (e) {
    res.status(500).json({
      success: false,
      message: e.message
    });
  }
});

app.post('/api/auth/register', async (req, res) => {
  try {
    const {
      full_name,
      phone,
      email,
      password,
      role
    } = req.body;

    const existingUser = await pool.query(
      'SELECT id FROM users WHERE phone = $1',
      [phone]
    );

    if (existingUser.rows.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Téléphone déjà utilisé',
      });
    }

    const hashedPassword = await bcrypt.hash(
      password,
      10
    );

    const userRole =
      role === 'doctor'
        ? 'doctor'
        : 'patient';

    const result = await pool.query(
      `
      INSERT INTO users
      (
        full_name,
        phone,
        email,
        password,
        role
      )
      VALUES
      ($1,$2,$3,$4,$5)
      RETURNING *
      `,
      [
        full_name,
        phone,
        email,
        hashedPassword,
        userRole,
      ]
    );

    res.status(201).json({
      success: true,
      message: 'Compte créé avec succès',
      user: result.rows[0],
    });

  } catch (error) {
    console.error(error);

    res.status(500).json({
      success: false,
      message: 'Erreur création compte',
    });
  }
});

// =========================
// CASH IN
// =========================
app.post('/cashin', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const { amount } = req.body || {};
    const parsedAmount = Number(amount);

    if (!parsedAmount || parsedAmount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Montan an pa valab',
      });
    }

    await pool.query(
      'UPDATE users SET balance = balance + $1 WHERE id = $2',
      [parsedAmount, userId]
    );

    await pool.query(
      `INSERT INTO transactions (sender_id, receiver_id, amount, type, created_at)
       VALUES ($1, $2, $3, $4, NOW())`,
      [userId, userId, parsedAmount, 'cashin']
    );

    return res.status(200).json({
      success: true,
      message: 'Cash in reyisi',
    });
  } catch (error) {
    console.error('CASH IN ERROR:', error);
    return res.status(500).json({
      success: false,
      message: 'Erè sèvè pandan cash in',
    });
  }
});

app.post('/api/subscriptions/pay-stripe', auth, async (req, res) => {
  try {
    const { plan, amount } = req.body;
    const userId = req.userId;

    if (!plan || !amount) {
      return res.status(400).json({
        success: false,
        message: 'Plan et montant obligatoires',
      });
    }

   const WEB_URL = 'http://localhost:64505';

const session = await stripe.checkout.sessions.create({
  payment_method_types: ['card'],
  mode: 'payment',

  line_items: [
    {
      price_data: {
        currency: 'eur',
        product_data: {
          name: `Abonnement FG Santé ${plan}`,
        },
        unit_amount: Math.round(Number(amount) * 100),
      },
      quantity: 1,
    },
  ],

  metadata: {
    userId: String(userId),
    plan: String(plan),
    amount: String(amount),
    type: 'fg_sante_subscription',
  },

  success_url: `${WEB_URL}/#/subscription-success`,
  cancel_url: `${WEB_URL}/#/subscription-cancel`,
});
    return res.json({
      success: true,
      checkoutUrl: session.url,
      sessionId: session.id,
    });

  } catch (e) {
    return res.status(500).json({
      success: false,
      message: `Erreur Stripe: ${e.message}`,
    });
  }
});



app.post('/api/subscriptions/pay-wallet', auth, async (req, res) => {
  const client = await pool.connect();

  try {
    const userId = req.userId;
    const { plan, amount, pin } = req.body;

    if (!plan || !amount || !pin) {
      return res.status(400).json({
        success: false,
        message: 'Plan, montant et PIN obligatoires',
      });
    }

    await client.query('BEGIN');

    const userResult = await client.query(
      'SELECT id, balance, pin FROM users WHERE id = $1 FOR UPDATE',
      [userId]
    );

    if (userResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        message: 'Utilisateur introuvable',
      });
    }

    const user = userResult.rows[0];

    if (String(user.pin) !== String(pin)) {
      await client.query('ROLLBACK');
      return res.status(401).json({
        success: false,
        message: 'PIN incorrect',
      });
    }

    const subscriptionAmount = Number(amount);
    const currentBalance = Number(user.balance);

    if (currentBalance < subscriptionAmount) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Solde insuffisant',
      });
    }

    const newBalance = currentBalance - subscriptionAmount;

    await client.query(
      'UPDATE users SET balance = $1 WHERE id = $2',
      [newBalance, userId]
    );

    await client.query(
      `
      INSERT INTO transactions
      (user_id, type, amount, description, status)
      VALUES ($1, $2, $3, $4, $5)
      `,
      [
        userId,
        'subscription',
        -subscriptionAmount,
        `Abonnement FG Santé ${plan}`,
        'completed'
      ]
    );

    await client.query('COMMIT');

    return res.json({
      success: true,
      message: 'Abonnement activé',
      balance: newBalance,
    });

  } catch (e) {
    await client.query('ROLLBACK');
    return res.status(500).json({
      success: false,
      message: `Erreur abonnement wallet: ${e.message}`,
    });
  } finally {
    client.release();
  }
});

app.post('/api/stripe/confirm-checkout-session', async (req, res) => {
  try {
    const { sessionId } = req.body;
    if (!sessionId) {
      return res.status(400).json({ success: false, message: 'sessionId requis' });
    }

    const session = await stripe.checkout.sessions.retrieve(sessionId);

    if (session.payment_status !== 'paid') {
      return res.json({ success: false, message: 'Paiement non validé' });
    }

    // 🔁 Evite doublon
    const existing = await pool.query(
      'SELECT id FROM transactions WHERE reference = $1',
      [session.id]
    );
    if (existing.rows.length > 0) {
      return res.json({ success: true, message: 'Déjà traité' });
    }

    const userId = Number(session.metadata.userId);
    const amount = Number(session.metadata.amount);

    await pool.query(
      'UPDATE users SET balance = balance + $1 WHERE id = $2',
      [amount, userId]
    );

    await pool.query(
      `INSERT INTO transactions (sender_id, receiver_id, amount, type, reference, created_at)
       VALUES ($1, $1, $2, 'topup', $3, NOW())`,
      [userId, amount, session.id]
    );

    return res.json({ success: true });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ success: false, message: e.message });
  }
});

app.get('/api/health/professionals/pending', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        id,
        full_name,
        phone,
        email,
        health_role,
        professional_status,
        created_at
      FROM users
      WHERE health_role IN ('doctor', 'nurse', 'secretary', 'lab')
      AND professional_status = 'pending'
      ORDER BY id DESC
    `);

    res.json(result.rows);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// ===============================
// ADMIN - LIST MANUAL PAYMENTS
// ===============================
app.get('/api/admin/payments', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        t.id,
        t.user_id,
        u.phone,
        t.amount,
        COALESCE(t.method, t.type, 'manual') AS method,
        COALESCE(t.reference_manual, t.reference, '') AS reference_manual,
        COALESCE(t.status, 'pending') AS status,
        t.created_at
      FROM transactions t
      LEFT JOIN users u ON u.id = t.user_id
      ORDER BY t.id DESC
      LIMIT 50
    `);

    return res.json({
      success: true,
      payments: result.rows,
    });
  } catch (e) {
    console.error('GET ADMIN PAYMENTS ERROR:', e);
    return res.status(500).json({
      success: false,
      message: e.message,
      payments: [],
    });
  }
});

// ==============================
// ADMIN PAYMENTS
// ==============================
app.get('/api/admin/payments', authMiddleware, async (req, res) => {
  try {
 const result = await pool.query(`
  SELECT
    id,
    sender_id,
    receiver_id,
    amount,
    type,
    status,
    method,
    reference,
    reference_manual,
    title,
    description,
    created_at
  FROM transactions
  WHERE type = 'manual_payment'
  ORDER BY created_at DESC
`);

    return res.json({
      success: true,
      payments: result.rows,
    });

  } catch (error) {
    console.error('Erreur admin payments:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

router.get('/manual-payments', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT *
      FROM transactions
      WHERE status = 'pending'
      ORDER BY id DESC
    `);

    res.json({
      success: true,
      payments: result.rows,
    });
  } catch (err) {
    console.error(err);

    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

app.post('/api/admin/validate-payment', async (req, res) => {
  try {
    const { paymentId } = req.body;

    console.log("VALIDATE ID:", paymentId);

    const check = await pool.query(
      'SELECT * FROM transactions WHERE id = $1',
      [paymentId]
    );

    if (check.rows.length === 0) {
      return res.json({
        success: false,
        message: 'Paiement introuvable',
      });
    }

    const payment = check.rows[0];

    // ✅ UPDATE STATUS
    await pool.query(
      'UPDATE transactions SET status = $1 WHERE id = $2',
      ['approved', paymentId]
    );

    // ✅ CREDIT WALLET
    await pool.query(
      'UPDATE users SET balance = balance + $1 WHERE id = $2',
      [payment.amount, payment.user_id]
    );
console.log("BODY:", req.body);

    return res.json({
      success: true,
      message: 'Paiement validé',
    });

  } catch (e) {
    console.error(e);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

// =========================
// QR PAY
// =========================
app.post('/qr-pay', auth, async (req, res) => {
  const client = await pool.connect();

  try {
    const { merchantId, amount, pin, description } = req.body || {};
    const parsedAmount = Number(amount);
    const parsedMerchantId = Number(merchantId);

    if (!parsedMerchantId || !parsedAmount || parsedAmount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Paramètres invalides',
      });
    }

    await client.query('BEGIN');

    const senderResult = await client.query(
      'SELECT id, balance, pin, name FROM users WHERE id = $1',
      [req.userId]
    );

    if (senderResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        message: 'Utilisateur payeur introuvable',
      });
    }

    const sender = senderResult.rows[0];

    if (!sender.pin || sender.pin !== pin) {
      await client.query('ROLLBACK');
      return res.status(401).json({
        success: false,
        message: 'PIN incorrect',
      });
    }

    const merchantResult = await client.query(
      'SELECT id, name, balance FROM users WHERE id = $1',
      [parsedMerchantId]
    );

    if (merchantResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        message: 'Merchant introuvable',
      });
    }

    const merchant = merchantResult.rows[0];

    const tcaRate = 0.10;
    const fgpayRate = 0.02;

    const tcaAmount = parsedAmount * tcaRate;
    const fgpayCommission = parsedAmount * fgpayRate;
    const totalAmount = parsedAmount + tcaAmount + fgpayCommission;

    if (Number(sender.balance) < totalAmount) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Solde insuffisant',
      });
    }

    await client.query(
      'UPDATE users SET balance = balance - $1 WHERE id = $2',
      [totalAmount, req.userId]
    );

    await client.query(
      'UPDATE users SET balance = balance + $1 WHERE id = $2',
      [parsedAmount, parsedMerchantId]
    );

    const txResult = await client.query(
      `
      INSERT INTO transactions (
        sender_id,
        receiver_id,
        amount,
        type,
        description,
        tca_amount,
        total_amount,
        created_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
      RETURNING id, sender_id, receiver_id, amount, type, description, tca_amount, total_amount, created_at
      `,
      [
        req.userId,
        parsedMerchantId,
        parsedAmount,
        'qr_payment',
        description || `QR Payment - ${merchant.name}`,
        tcaAmount,
        totalAmount,
      ]
    );

    const balanceResult = await client.query(
      'SELECT balance FROM users WHERE id = $1',
      [req.userId]
    );

    await client.query('COMMIT');

    return res.json({
      success: true,
      message: `Paiement QR envoyé à ${merchant.name}`,
      merchantName: merchant.name,
      balance: Number(balanceResult.rows[0].balance),
      baseAmount: parsedAmount,
      tcaAmount,
      fgpayCommission,
      totalAmount,
      reference: `QR-${txResult.rows[0].id}`,
      date: txResult.rows[0].created_at,
      transaction: txResult.rows[0],
    });
  } catch (e) {
    await client.query('ROLLBACK');
    return res.status(500).json({
      success: false,
      message: `Erreur qr-pay: ${e.message}`,
    });
  } finally {
    client.release();
  }
});

app.post('/pay', authMiddleware, async (req, res) => {
  try {
    const senderId = req.userId;
    const { receiverId, amount } = req.body;

    const parsedAmount = parseFloat(amount);

    if (!parsedAmount || parsedAmount <= 0) {
      return res.status(400).json({ success: false, message: 'Montant invalide' });
    }

    // 💰 Commission FGPay (3%)
    const commission = parsedAmount * 0.03;
    const total = parsedAmount + commission;

    // 🔎 Vérifier solde
    const userRes = await pool.query(
      'SELECT balance FROM users WHERE id = $1',
      [senderId]
    );

    const balance = parseFloat(userRes.rows[0].balance);

    if (balance < total) {
      return res.status(400).json({
        success: false,
        message: 'Solde insuffisant'
      });
    }

    // 💸 Débit sender
    await pool.query(
      'UPDATE users SET balance = balance - $1 WHERE id = $2',
      [total, senderId]
    );

    // 💰 Crédit receiver (SAN commission)
    await pool.query(
      'UPDATE users SET balance = balance + $1 WHERE id = $2',
      [parsedAmount, receiverId]
    );

    // 🧾 Enregistrer transaction
    await pool.query(`
      INSERT INTO transactions (
        sender_id,
        receiver_id,
        amount,
        commission_amount,
        total_amount,
        type,
        status
      )
      VALUES ($1, $2, $3, $4, $5, 'payment', 'approved')
    `, [
      senderId,
      receiverId,
       amount,
      commission,
      total
    ]);



    return res.json({
  success: true,
  message: 'Paiement effectué',
  receipt: {
    merchantName: 'FGPay',
    amount: parsedAmount,
    baseAmount: parsedAmount,
    commissionAmount: commission,
    tcaAmount: 0,
    totalAmount: total,
    reference: reference,
    createdAt: new Date().toISOString(),
    status: 'APPROVED',
    description: 'Paiement effectué'
  }
});

  } catch (error) {
    console.error('Erreur pay:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur'
    });
  }
});

// =========================
// BALANCE
// =========================
app.get('/balance', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;

    const result = await pool.query(
      'SELECT balance FROM users WHERE id = $1',
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur introuvable',
      });
    }

    return res.json({
      success: true,
      balance: Number(result.rows[0].balance || 0),
    });
  } catch (err) {
    console.error(err);

    return res.status(500).json({
      success: false,
      message: 'Erreur récupération balance',
    });
  }
});

// =========================
// TRANSACTIONS
// =========================
app.get('/transactions', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;

    const result = await pool.query(
      `
      SELECT id, sender_id, receiver_id, amount, type, created_at
      FROM transactions
      WHERE sender_id = $1 OR receiver_id = $1
      ORDER BY created_at DESC
      `,
      [userId]
    );

    return res.json({
      success: true,
      transactions: result.rows,
    });
  } catch (error) {
    console.error('Erreur transactions:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Erreur transactions',
      error: error.message,
    });
  }
});

// =========================
// WALLET TEST ROUTES
// =========================
app.get('/api/wallet/transactions', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM transactions ORDER BY created_at DESC'
    );

    return res.json(result.rows);
  } catch (e) {
    return res.status(500).json({
      success: false,
      message: e.message,
    });
  }
});

app.get('/api/wallet/balance', auth, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT balance FROM users WHERE id = $1',
      [req.userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    return res.json({
      success: true,
      balance: Number(result.rows[0].balance),
    });

  } catch (e) {
    console.error('GET BALANCE ERROR:', e);

    return res.status(500).json({
      success: false,
      message: e.message,
    });
  }
});
// =========================
// SUBSCRIBE
// =========================
app.post('/api/subscription/subscribe', authMiddleware, async (req, res) => {
  const client = await pool.connect();

  try {
    const userId = req.userId;
    const { service, plan, amount, pin } = req.body;

    const subscriptionAmount = Number(amount);

    if (!service || !plan || !subscriptionAmount || !pin) {
      return res.status(400).json({
        success: false,
        message: 'Service, plan, montant et PIN obligatoires',
      });
    }

    await client.query('BEGIN');

    const userResult = await client.query(
      'SELECT id, balance, pin FROM users WHERE id = $1 FOR UPDATE',
      [userId]
    );

    if (userResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    const user = userResult.rows[0];

    if (String(user.pin) !== String(pin)) {
      await client.query('ROLLBACK');
      return res.status(401).json({
        success: false,
        message: 'PIN incorrect',
      });
    }

    const balance = Number(user.balance);

    if (balance < subscriptionAmount) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Solde insuffisant',
      });
    }

    const newBalance = balance - subscriptionAmount;

    await client.query(
      `
      UPDATE users
      SET balance = $1,
          is_subscribed = true,
          subscription_expiry = NOW() + INTERVAL '30 days'
      WHERE id = $2
      `,
      [newBalance, userId]
    );

    await client.query(
      `
      INSERT INTO transactions
      (sender_id, amount, type, description, status, created_at)
      VALUES ($1, $2, $3, $4, $5, NOW())
      `,
      [
        userId,
        -subscriptionAmount,
        'subscription',
        `Abonnement ${service} - ${plan}`,
        'completed',
      ]
    );

    await client.query('COMMIT');

    return res.json({
      success: true,
      newBalance,
      message: 'Abonnement activé',
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('SUBSCRIBE ERROR:', err);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur',
      error: err.message,
    });
  } finally {
    client.release();
  }
});

app.get('/api/health/stats', authMiddleware, async (req, res) => {
  try {
    const doctors = await pool.query(
      "SELECT COUNT(*) FROM users WHERE role = 'doctor'"
    );

    const results = await pool.query(
      "SELECT COUNT(*) FROM medical_results"
    );

    const appointments = await pool.query(
      "SELECT COUNT(*) FROM appointments"
    );

    const prescriptions = await pool.query(
      "SELECT COUNT(*) FROM prescriptions"
    );

    res.json({
      success: true,
      stats: {
        doctors: Number(doctors.rows[0].count),
        results: Number(results.rows[0].count),
        appointments: Number(appointments.rows[0].count),
        prescriptions: Number(prescriptions.rows[0].count),
      },
    });
  } catch (error) {
    console.error('HEALTH STATS ERROR:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur stats FG Santé',
    });
  }
});
// routes/subscription.js
app.get('/api/subscription/status', authMiddleware, async (req, res) => {
  const userId = req.userId;

console.log('REQ USER:', req.user);
console.log('REQ USER ID:', req.userId);

  const result = await pool.query(
    `SELECT
       is_subscribed,
       subscription_expiry,
       (is_subscribed = true AND subscription_expiry > NOW()) AS active
     FROM users
     WHERE id = $1`,
    [userId]
  );

  res.json(result.rows[0] || { active: false });
});


 router.post('/subscribe', authMiddleware, async (req, res) => {

  console.log('SUBSCRIBE REQ USERID:', req.userId);
console.log('SUBSCRIBE REQ USER:', req.user);

const userId = req.userId || req.user?.id || req.user?.userId;

if (!userId) {
  return res.status(401).json({
    success: false,
    message: 'Token invalide ou userId manquant',
  });
}

  const amount = 10;

  // Verifye balance
  const userResult = await pool.query(
    'SELECT id, balance, pin FROM users WHERE id = $1',
    [userId]
  );

if (userResult.rows.length === 0) {
  return res.status(404).json({
    success: false,
    message: 'Utilisateur introuvable',
  });
}

const { pin } = req.body;

if (!pin || !/^\d{6}$/.test(String(pin))) {
  return res.status(400).json({
    success: false,
    message: 'PIN dwe gen 6 chif',
  });
}

const user = userResult.rows[0];
const balance = Number(user.balance || 0);

if (balance < amount) {
  return res.status(400).json({
    success: false,
    message: 'Solde insuffisant',
  });
}
  // Débite
  await pool.query(
    'UPDATE users SET balance = balance - $1 WHERE id = $2',
    [amount, userId]
  );

  // Active abonnement (30 jou)
  await pool.query(
    `UPDATE users 
     SET is_subscribed = true,
         subscription_expiry = NOW() + INTERVAL '30 days'
     WHERE id = $1`,
    [userId]
  );

  return res.json({
  success: true,
  message: 'Abonnement activé ✅',
  active: true,
  newBalance: balance - amount,
});
});
// =========================
// TOPUP
// =========================
app.post('/topup', auth, async (req, res) => {
  try {
    const userId = req.userId;
    const { amount } = req.body || {};
    const parsedAmount = Number(amount);

    if (!parsedAmount || parsedAmount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Montant invalide',
      });
    }

    await pool.query(
      'UPDATE users SET balance = balance + $1 WHERE id = $2',
      [parsedAmount, userId]
    );

    await pool.query(
      'INSERT INTO transactions (sender_id, receiver_id, amount, type) VALUES ($1, $2, $3, $4)',
      [userId, userId, parsedAmount, 'topup']
    );

    return res.json({ success: true });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false });
    console.log('REQ USER ID:', req.userId);
  }
});

// =========================
// PAY
// =========================
app.post('/pay', auth, async (req, res) => {
  const client = await pool.connect();

  try {
    const { amount, description } = req.body || {};
    const parsedAmount = Number(amount);

    console.log('PAY BODY =', req.body);
    console.log('PAY USER ID =', req.userId);

    console.log('USER ID:', req.userId);

    if (!parsedAmount || parsedAmount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Montant invalide',
      });
    }

    await client.query('BEGIN');

    const userCheck = await client.query(
      'SELECT id, balance FROM users WHERE id = $1',
      [req.userId]
    );

    if (userCheck.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        message: 'Utilisateur introuvable',
      });
    }

    const currentBalance = Number(userCheck.rows[0].balance);

    const baseAmount = parsedAmount;

// Pay / QR Pay: TCA 10% + commission 2%
const tcaRate = 0.10;
const commissionRate = 0.02;

const tcaAmount = Number((baseAmount * tcaRate).toFixed(2));
const commissionAmount = Number((baseAmount * commissionRate).toFixed(2));
const totalAmount = Number((baseAmount + tcaAmount + commissionAmount).toFixed(2));

    if (currentBalance < parsedAmount) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Solde insuffisant',
      });
    }

    const updatedUser = await client.query(
      'UPDATE users SET balance = balance - $1 WHERE id = $2 RETURNING balance',
      [parsedAmount, req.userId]
    );

    const txResult = await client.query(
  `INSERT INTO transactions (sender_id, receiver_id, amount, type, title, reference, created_at)
   VALUES ($1, $2, $3, $4, $5, $6, NOW())
   RETURNING id, amount, type, title, reference, created_at`,
  [req.userId, req.userId, baseAmount, 'qr_payment', 'Paiement QR', reference]
);
    

    await client.query('COMMIT');

console.log('REQ USER ID:', req.userId);
console.log('PIN RECU:', pin);

   return res.json({
  success: true,
  message: 'Paiement effectué avec succès',
  balance: Number(updatedUser.rows[0].balance),

  transaction: {
    id: txResult.rows[0].id,
    amount: Number(txResult.rows[0].amount),
    type: txResult.rows[0].type,
    title: description && description.trim() !== ''
      ? description.trim()
      : 'Payment',
    reference: txResult.rows[0].reference,
    date: txResult.rows[0].created_at,
  },

  receipt: {
    baseAmount,
    tcaAmount,
    commissionAmount,
    totalAmount,
    date: txResult.rows[0].created_at,
  },
});
  } catch (e) {
    await client.query('ROLLBACK');
    return res.status(500).json({
      success: false,
      message: `Erreur pay: ${e.message}`,
    });
  } finally {
    client.release();
  }
});

app.get('/api/wallet/balance', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;

    const result = await pool.query(
      'SELECT balance FROM users WHERE id = $1',
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur introuvable',
      });
    }

    return res.json({
      success: true,
      balance: Number(result.rows[0].balance || 0),
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      message: 'Erreur récupération balance',
    });
  }
});

app.post('/api/wallet/manual-payment', auth, async (req, res) => {
  try {
    const userId = req.userId;
    const { method, amount, reference } = req.body || {};

    const parsedAmount = Number(amount);

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'Session invalide',
      });
    }

    if (!parsedAmount || parsedAmount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Montant invalide',
      });
    }

    const finalReference =
      reference && reference.trim() !== ''
        ? reference.trim()
        : `MANUAL-${Date.now()}`;

   await pool.query(
  `INSERT INTO transactions
   (sender_id, receiver_id, amount, type, status, method, reference_manual, title, description)
   VALUES ($1, $1, $2, 'manual_payment', 'pending', $3, $4, $5, $6)`,
  [
    userId,
    parsedAmount,
    method || 'manual',
    finalReference,
    'Recharge en attente',
    `Paiement ${method || 'manual'} soumis`,
  ]
);

    return res.json({
      success: true,
      message: 'Demande envoyée, en attente de validation admin',
    });
  } catch (e) {
    console.error('MANUAL PAYMENT ERROR:', e);
    return res.status(500).json({
      success: false,
      message: e.message,
    });
  }
});

app.post('/api/admin/transactions/:id/approve', async (req, res) => {
  const txId = req.params.id;
  console.log('APPROVE TX ID:', txId);

  try {
    const txResult = await pool.query(
      'SELECT * FROM transactions WHERE id = $1',
      [txId]
    );

    if (txResult.rows.length === 0) {
      return res.json({ success: false, message: 'Paiement introuvable' });
    }

    const tx = txResult.rows[0];

    await pool.query(
      'UPDATE users SET balance = balance + $1 WHERE id = $2',
      [Number(tx.amount), tx.user_id]
    );

    await pool.query(
      "UPDATE transactions SET status = 'approved' WHERE id = $1",
      [txId]
    );

    return res.json({
      success: true,
      message: 'Paiement validé',
      receipt: {
        amount: tx.amount,
        baseAmount: tx.amount,
        totalAmount: tx.amount,
        reference: tx.reference_manual || tx.reference || `TX-${tx.id}`,
        createdAt: new Date().toISOString(),
        status: 'APPROVED',
        description: 'Recharge validée',
      },
    });
  } catch (e) {
    console.error('APPROVE ERROR:', e);
    return res.status(500).json({ success: false, message: e.message });
  }
});

app.post('/api/admin/transactions/:id/reject', async (req, res) => {
  const txId = req.params.id;
  console.log('REJECT TX ID:', txId);

  try {
    const result = await pool.query(
      "UPDATE transactions SET status = 'rejected' WHERE id = $1 RETURNING *",
      [txId]
    );

    if (result.rows.length === 0) {
      return res.json({ success: false, message: 'Paiement introuvable' });
    }

    return res.json({ success: true, message: 'Paiement rejeté' });
  } catch (e) {
    console.error('REJECT ERROR:', e);
    return res.status(500).json({ success: false, message: e.message });
  }
});

app.post('/api/admin/transactions/:id/approve', async (req, res) => {
  const id = Number(req.params.id);
  console.log('APPROVE ID:', id);

  try {
    const tx = await pool.query(
      'SELECT * FROM transactions WHERE id = $1',
      [id]
    );

    if (tx.rows.length === 0) {
      return res.json({ success: false, message: 'Paiement introuvable' });
    }

    const payment = tx.rows[0];

    // 🔒 si pa gen user_id, pa kredite
    if (!payment.user_id) {
      return res.json({
        success: false,
        message: 'Transaction sans user',
      });
    }

    // 💰 kredite wallet
    await pool.query(
      'UPDATE users SET balance = balance + $1 WHERE id = $2',
      [Number(payment.amount), payment.user_id]
    );

    // ✅ update status
    await pool.query(
      "UPDATE transactions SET status = 'approved' WHERE id = $1",
      [id]
    );

    return res.json({
      success: true,
      message: 'Paiement validé',
      receipt: {
        amount: payment.amount,
        reference: payment.reference_manual || payment.reference,
        createdAt: new Date().toISOString(),
        status: 'APPROVED',
      },
    });

  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, message: err.message });
  }
});

app.post('/api/admin/transactions/:id/reject', authMiddleware, async (req, res) => {
  try {
    const txId = req.params.id;

    const result = await pool.query(
      `
      UPDATE transactions
      SET status = 'rejected'
      WHERE id = $1
      RETURNING *
      `,
      [txId]
    );

    if (result.rows.length === 0) {
      return res.json({
        success: false,
        message: 'Paiement introuvable',
      });
    }

    return res.json({
      success: true,
      message: 'Paiement rejeté',
      payment: result.rows[0],
    });
  } catch (error) {
    console.error('Erreur rejet paiement:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur rejet',
    });
  }
});
// =========================
// TRANSFER
// =========================
app.post('/transfer', async (req, res) => {
  try {
    const { receiverPhone, amount } = req.body || {};
    const parsedAmount = Number(amount);

    if (!receiverPhone || !parsedAmount || parsedAmount <= 0) {
      return res.json({
        success: false,
        message: 'Téléphone ak montant obligatwa',
      });
    }

    const baseAmount = parsedAmount;
    const tcaAmount = 0;

    // 🔥 Commission
    const commissionRate = 0.02;
    const minCommission = 10;

    const commissionAmount = Math.max(baseAmount * commissionRate, minCommission);
    const totalDebit = baseAmount + tcaAmount + commissionAmount;

    // 🔍 Receiver
    const receiverResult = await pool.query(
      'SELECT id, name, phone, balance FROM users WHERE phone = $1 LIMIT 1',
      [receiverPhone]
    );

    if (receiverResult.rows.length === 0) {
      return res.json({
        success: false,
        message: 'Destinataire introuvable',
      });
    }

    // 🔍 Sender (test user)
    const senderResult = await pool.query(
      'SELECT id, name, phone, balance FROM users WHERE id = $1 LIMIT 1',
      [3]
    );

    if (senderResult.rows.length === 0) {
      return res.json({
        success: false,
        message: 'Utilisateur introuvable',
      });
    }

    const sender = senderResult.rows[0];
    const receiver = receiverResult.rows[0];

    if (Number(sender.balance) < totalDebit) {
      return res.json({
        success: false,
        message: 'Solde insuffisant',
      });
    }

    // 💸 Debit sender
    await pool.query(
      'UPDATE users SET balance = balance - $1 WHERE id = $2',
      [totalDebit, sender.id]
    );

    // 💰 Credit receiver
    await pool.query(
      'UPDATE users SET balance = balance + $1 WHERE id = $2',
      [baseAmount, receiver.id]
    );

    // 🔖 Reference
    const reference = `TR-${Date.now()}`;

    // 🧾 Transaction
    const txResult = await pool.query(
      `INSERT INTO transactions (sender_id, receiver_id, amount, type, title, reference, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, NOW())
       RETURNING id, amount, type, reference, created_at`,
      [sender.id, receiver.id, baseAmount, 'transfer', 'Transfert', reference]
    );

    const tx = txResult.rows[0];

    console.log('REQ USER ID:', req.userId);
    console.log('PIN RECU:', pin);

    return res.json({
      success: true,
      message: 'Transfert réussi',

      transaction: {
        id: tx.id,
        amount: Number(tx.amount),
        type: tx.type,
        reference: tx.reference,
        date: tx.created_at,
      },

      receiver: {
        name: receiver.name,
        phone: receiver.phone,
      },

      receipt: {
        baseAmount,
        tcaAmount,
        commissionAmount,
        totalAmount: totalDebit,
        date: tx.created_at,
      },
    });

  } catch (error) {
    console.log('ERROR TRANSFER:', error);

    return res.json({
      success: false,
      message: error.message,
    });
  }
});
// =========================
// START SERVER
// =========================
app.listen(PORT, () => {
  console.log(`FGPay PostgreSQL server running on http://localhost:${PORT}`);
});