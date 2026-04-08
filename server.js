require('dotenv').config();

const express = require('express');
const cors = require('cors');
const Stripe = require('stripe');
const pool = require('./db');
const jwt = require('jsonwebtoken');
const paypal = require('@paypal/checkout-server-sdk');
const app = express();
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
const walletRoutes = require('./routes/walletRoutes');


app.use(cors());
app.use(express.json());
app.use('/api/wallet', walletRoutes);

console.log('STRIPE KEY =', process.env.STRIPE_SECRET_KEY);

// Stripe webhook route BEFORE express.json()



// Other routes
// app.use('/api/stripe', stripeRoutes);



const environment = new paypal.core.SandboxEnvironment(
  process.env.PAYPAL_CLIENT_ID,
  process.env.PAYPAL_SECRET
);
const client = new paypal.core.PayPalHttpClient(environment);

// CREATE SUBSCRIPTION
app.post('/api/paypal/create-subscription', async (req, res) => {
  try {
    const { planId } = req.body;

    const request = new paypal.subscriptions.SubscriptionsCreateRequest();

    request.requestBody({
      plan_id: planId,
      application_context: {
        brand_name: 'FGPay',
        user_action: 'SUBSCRIBE_NOW',
        return_url: 'http://localhost:3000/api/paypal/success',
        cancel_url: 'http://localhost:3000/api/paypal/cancel',
      },
    });

    const response = await client.execute(request);

    const approveLink = response.result.links.find(
      (link) => link.rel === 'approve'
    )?.href;

    res.json({ approveUrl: approveLink });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message });
  }
});

// SUCCESS
app.get('/api/paypal/success', (req, res) => {
  res.send('Paiement réussi');
});

// CANCEL
app.get('/api/paypal/cancel', (req, res) => {
  res.send('Paiement annulé');
});

let users = [
  {
    id: 1,
    name: 'James Constant',
    email: 'user2@test.com',
    phone: '50911111111',
    password: '123456',
    pin: '1111',
    balance: 3400,
  },
  {
    id: 2,
    name: 'Mike Joseph',
    email: 'mike@test.com',
    phone: '50922222222',
    password: '123456',
    pin: '2222',
    balance: 1800,
  }
];

let transactions = [];
let currentUserId = 1;

const authMiddleware = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      return res.status(401).json({ message: 'Token manke' });
    }
const auth = require('./middleware/auth');
    const token = authHeader.split(' ')[1];

    if (!token) {
      return res.status(401).json({ message: 'Token invalid' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ message: 'Token pa valab' });
  }
};

pool.query('SELECT NOW()')
  .then(() => console.log('DB CONNECTED OK'))
  .catch((err) => console.error('DB ERROR:', err.message));

  pool.query('SELECT * FROM users')
  .then(res => console.log('USERS OK:', res.rows.length))
  .catch(err => console.error('ERROR USERS:', err.message));
  


app.use(cors());
app.use(express.json());


const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET;

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
    next();
  } catch (e) {
    return res.status(401).json({
      success: false,
      message: 'Token invalide',
    });
  }
}

function generateReference() {
  return `FGP${Date.now()}`;
}

app.get('/', (req, res) => {
  res.send("FGPay API running on http://localhost:3000");
});

app.post('/api/stripe/create-checkout-session', async (req, res) => {
  try {
    console.log('STRIPE BODY =', req.body);

    const { serviceName, amount, currency } = req.body;

    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: (currency || 'eur').toLowerCase(),
            product_data: {
              name: serviceName || 'FGPay IPTV',
            },
            unit_amount: Math.round(Number(amount) * 100),
          },
          quantity: 1,
        },
      ],
      mode: 'payment',
      success_url: 'http://localhost:57785/#/payment-success',
      cancel_url: 'http://localhost:57785/#/payment-cancel',
    });

    console.log('STRIPE SESSION URL =', session.url);

    return res.json({
      success: true,
      checkoutUrl: session.url,
    });
  } catch (error) {
    console.error('STRIPE CREATE SESSION ERROR FULL =', error.message);
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});
app.post('/login', async (req, res) => {
  try {
    const { phone, password } = req.body;

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
      user.password === password || bcrypt.compareSync(password, user.password);

    if (!passwordOk) {
      return res.status(401).json({
        success: false,
        message: 'Mot de passe incorrect',
      });
    }

    const token = jwt.sign(
      { id: user.id },
      process.env.JWT_SECRET || 'secret',
      { expiresIn: '7d' }
    );

    return res.json({
      success: true,
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        balance: user.balance,
      },
    });
  } catch (e) {
    return res.status(500).json({
      success: false,
      message: `Erreur login: ${e.message}`,
    });
  }
});
app.post('/api/payments/create-intent', async (req, res) => {
  try {
    const { amount } = req.body;

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount * 100, // Stripe = centimes
      currency: 'eur',
    });

    res.json({
      clientSecret: paymentIntent.client_secret,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.post('/api/paypal/create-subscription', async (req, res) => {
  const request = new paypal.subscriptions.SubscriptionsCreateRequest();

  request.requestBody({
    plan_id: 'P-XXXXXXX',
    application_context: {
      brand_name: 'FGPay',
      user_action: 'SUBSCRIBE_NOW',
      return_url: 'http://192.168.1.34:3000/api/paypal/success',
    cancel_url: 'http://192.168.1.34:3000/api/paypal/cancel',
    },
  });

  try {
    const response = await client.execute(request);

    const approveLink = response.result.links.find(
      link => link.rel === 'approve'
    ).href;

    res.json({ approveUrl: approveLink });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/cashin', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const { amount } = req.body;

    if (!amount || Number(amount) <= 0) {
      return res.status(400).json({
        message: 'Montan an pa valab',
      });
    }

    await pool.query(
      'UPDATE users SET balance = balance + $1 WHERE id = $2',
      [amount, userId]
    );

    await pool.query(
      `INSERT INTO transactions (sender_id, receiver_id, amount, type, created_at)
       VALUES ($1, $2, $3, $4, NOW())`,
      [userId, userId, amount, 'cashin']
    );

    res.status(200).json({
      message: 'Cash in reyisi',
    });
  } catch (error) {
    console.error('CASH IN ERROR:', error);
    res.status(500).json({
      message: 'Erè sèvè pandan cash in',
    });
  }
});

app.post('/qr-pay', auth, async (req, res) => {
  const client = await pool.connect();

  try {
    const { merchantId, amount, pin } = req.body;
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

    if (Number(sender.balance) < parsedAmount) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Solde insuffisant',
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

    await client.query(
      'UPDATE users SET balance = balance - $1 WHERE id = $2',
      [parsedAmount, req.userId]
    );

    await client.query(
      'UPDATE users SET balance = balance + $1 WHERE id = $2',
      [parsedAmount, parsedMerchantId]
    );

    const txResult = await client.query(
      `INSERT INTO transactions (sender_id, receiver_id, amount, type, created_at)
       VALUES ($1, $2, $3, $4, NOW())
       RETURNING id, sender_id, receiver_id, amount, type, created_at`,
      [req.userId, parsedMerchantId, parsedAmount, 'qr_payment']
    );

    const balanceResult = await client.query(
      'SELECT balance FROM users WHERE id = $1',
      [req.userId]
    );

    await client.query('COMMIT');

    return res.json({
      success: true,
      message: `Paiement QR envoyé à ${merchant.name}`,
      balance: Number(balanceResult.rows[0].balance),
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

app.get('/api/wallet/balance', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        COALESCE(SUM(
          CASE 
            WHEN receiver_id = $1 THEN amount
            WHEN sender_id = $1 THEN -amount
            ELSE 0
          END
        ), 0) AS balance
      FROM transactions
    `, [1]); // ⚠️ menm user test la

    return res.json({
      success: true,
      balance: Number(result.rows[0].balance),
    });
  } catch (e) {
    return res.status(500).json({
      success: false,
      message: e.message,
    });
  }
});


app.get('/transactions', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await pool.query(
      `
      SELECT id, sender_id, receiver_id, amount, type, created_at
      FROM transactions
      WHERE sender_id = $1 OR receiver_id = $1
      ORDER BY created_at DESC
      `,
      [userId]
    );

    res.json({
      success: true,
      transactions: result.rows,
    });
  } catch (error) {
    console.error('Erreur transactions:', error.message);
    res.status(500).json({
      success: false,
      message: 'Erreur transactions',
      error: error.message,
    });
  }
});

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

app.get('/api/wallet/balance', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT balance FROM users WHERE id = $1',
      [1] // ⚠️ pou test, n ap itilize user 1
    );

    return res.json({
      success: true,
      balance: Number(result.rows[0].balance || 0),
    });
  } catch (e) {
    return res.status(500).json({
      success: false,
      message: e.message,
    });
  }
});

app.post('/subscribe', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const { amount, service } = req.body;

    if (!amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Montant invalide',
      });
    }

    const userResult = await pool.query(
      'SELECT * FROM users WHERE id = $1',
      [userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur introuvable',
      });
    }

    const user = userResult.rows[0];

    if (Number(user.balance) < Number(amount)) {
      return res.status(400).json({
        success: false,
        message: 'Solde insuffisant',
      });
    }

    const newBalance = Number(user.balance) - Number(amount);

    await pool.query(
      'UPDATE users SET balance = $1 WHERE id = $2',
      [newBalance, userId]
    );

    await pool.query(
      `INSERT INTO transactions (sender_id, receiver_id, amount, type, created_at)
       VALUES ($1, $1, $2, $3, NOW())`,
      [userId, amount, service || 'subscription']
    );

    return res.json({
      success: true,
      message: 'Abonnement activé avec succès',
      newBalance,
    });
  } catch (error) {
    console.error('SUBSCRIBE ERROR:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

app.post('/topup', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const { amount } = req.body;

    // ✅ Update balance
    await pool.query(
      'UPDATE users SET balance = balance + $1 WHERE id = $2',
      [amount, userId]
    );

    // ✅ Insert transaction
    await pool.query(
      `INSERT INTO transactions (sender_id, receiver_id, amount, type)
       VALUES ($1, $1, $2, 'topup')`,
      [userId, amount]
    );

    res.json({ success: true, message: 'Topup OK (no Stripe)' });

  } catch (err) {
    console.error('TOPUP ERROR:', err);
    res.status(500).json({ error: 'Topup error' });
  }
});

app.post('/pay', auth, async (req, res) => {
  const client = await pool.connect();
console.log('USER ID:', req.userId);
  try {
    const { amount, description } = req.body;
    const parsedAmount = Number(amount);

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
      `INSERT INTO transactions (sender_id, receiver_id, amount, type, created_at)
       VALUES ($1, $2, $3, $4, NOW())
       RETURNING id, amount, type, created_at`,
      [req.userId, req.userId, parsedAmount, 'payment']
    );

    await client.query('COMMIT');

    return res.json({
      success: true,
      message: 'Paiement effectué avec succès',
      balance: Number(updatedUser.rows[0].balance),
      transaction: {
        id: txResult.rows[0].id,
        amount: Number(txResult.rows[0].amount),
        type: txResult.rows[0].type,
        title: description && description.trim().isNotEmpty
            ? description.trim()
            : 'Payment',
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


app.post('/transfer', async (req, res) => {
  try {
    const { receiverPhone, amount } = req.body;

    if (!receiverPhone || !amount || Number(amount) <= 0) {
      return res.json({
        success: false,
        message: 'Téléphone ak montant obligatwa',
      });
    }

    const receiver = users.find((u) => u.phone === receiverPhone);

    if (!receiver) {
      return res.json({
        success: false,
        message: 'Destinataire introuvable',
      });
    }

    const sender = users.find((u) => u.id === currentUserId);

    if (!sender) {
      return res.json({
        success: false,
        message: 'Utilisateur introuvable',
      });
    }

    if (Number(sender.balance) < Number(amount)) {
      return res.json({
        success: false,
        message: 'Solde insuffisant',
      });
    }

    sender.balance = Number(sender.balance) - Number(amount);
    receiver.balance = Number(receiver.balance) + Number(amount);

    const transaction = {
      id: Date.now(),
      sender_id: sender.id,
      receiver_id: receiver.id,
      amount: Number(amount),
      type: 'transfer',
      created_at: new Date().toISOString(),
    };

    transactions.push(transaction);

    return res.json({
      success: true,
      message: 'Transfert réussi',
      transaction,
      receiver: {
        name: receiver.name,
        phone: receiver.phone,
      },
      reference: 'FG' + Date.now(),
    });
  } catch (error) {
    console.log('ERROR TRANSFER:', error);

    return res.json({
      success: false,
      message: error.message,
    });
  }
});
app.listen(PORT, () => {
  console.log(`FGPay PostgreSQL server running on http://localhost:${PORT}`);
});
