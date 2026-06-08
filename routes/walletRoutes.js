const express = require('express');
const router = express.Router();

const pool = require('../db');
const auth = require('../middleware/auth');
const authMiddleware = require('../middleware/auth');


// GET BALANCE
router.get('/balance', auth, async (req, res) => {
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
    console.error('BALANCE ERROR:', err);
    return res.status(500).json({
      success: false,
      message: 'Erreur récupération balance',
    });
  }
});

router.get('/admin/manual-payments', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT mp.id, mp.user_id, u.phone, mp.method, mp.amount, mp.reference, mp.status, mp.created_at
       FROM manual_payments mp
       LEFT JOIN users u ON u.id = mp.user_id
       ORDER BY mp.created_at DESC`
    );

    return res.json({
      success: true,
      payments: result.rows,
    });
  } catch (error) {
    console.error('ADMIN PAYMENTS ERROR:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur récupération paiements admin',
      payments: [],
    });
  }
});

router.post('/manual-payment', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const { method, amount, reference } = req.body;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'Utilisateur non connecté',
      });
    }

    if (!method || !amount || !reference) {
      return res.status(400).json({
        success: false,
        message: 'Champs manquants',
      });
    }

    await pool.query(
      `INSERT INTO manual_payments 
       (user_id, method, amount, reference, status)
       VALUES ($1, $2, $3, $4, 'pending')`,
      [userId, method, amount, reference]
    );

    return res.json({
      success: true,
      message: 'Demande envoyée pour vérification ✅',
    });
  } catch (error) {
    console.error('MANUAL PAYMENT ERROR:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur paiement manuel',
    });
  }
});

router.get('/notifications', authMiddleware, async (req, res) => {
  try {
    console.log('NOTIF req.userId =', req.userId);
    console.log('NOTIF req.user =', req.user);

    const userId = req.userId || req.user?.id;

    const result = await pool.query(
      `SELECT id, title, message, type, is_read, created_at
       FROM notifications
       WHERE user_id = $1
       ORDER BY created_at DESC`,
      [userId]
    );

    return res.json({
      success: true,
      notifications: result.rows,
    });
  } catch (error) {
    console.log('FULL NOTIFICATION ERROR:');
    console.log(error);

    return res.status(500).json({
      success: false,
      notifications: [],
      message: error.toString(),
    });
  }
});


// 🔥 SEND MONEY LOCAL
router.post('/transfer', auth, async (req, res) => {
  const { receiverPhone, amount, pin } = req.body;

// 🔥 PROTECTION
if (!receiverPhone) {
  return res.status(400).json({
    success: false,
    message: 'Numéro manquant',
  });
}

const parsedAmount = Number(amount);

if (!parsedAmount || parsedAmount <= 0) {
  return res.status(400).json({
    success: false,
    message: 'Montant invalide',
  });
}

const baseAmount = parsedAmount;
const tcaAmount = 0;

const commissionRate = 0.02;
const minCommission = 10;

const commissionAmount = Number(
  Math.max(baseAmount * commissionRate, minCommission).toFixed(2)
);

const totalDebit = Number((baseAmount + commissionAmount).toFixed(2));

const cleanPhone = receiverPhone.toString().trim().replace(/\D/g, '');

console.log('RAW PHONE:', receiverPhone);
console.log('CLEAN PHONE:', cleanPhone);


  const senderId = req.userId || req.user?.id;

if (!senderId) {
  return res.status(401).json({
    success: false,
    message: 'Session invalide',

  });
}
  if (amount <= 0) {
    return res.status(400).json({ success: false, message: 'Montant invalide' });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 🔐 GET SENDER
    const senderResult = await client.query(
      'SELECT * FROM users WHERE id = $1 FOR UPDATE',
      [senderId]
    );

    const sender = senderResult.rows[0];

    if (!sender) {
      throw new Error('Utilisateur introuvable');
    }

    if (String(sender.pin) !== String(pin)) {
      throw new Error('PIN incorrect');
    }

    // 👤 GET RECEIVER
   const receiverResult = await client.query(
  'SELECT * FROM users WHERE phone = $1',
  [cleanPhone]
);

    const receiver = receiverResult.rows[0];

    if (!receiver) {
      throw new Error('Destinataire introuvable');
    }

    if (receiver.id === sender.id) {
      throw new Error('Transfert vers soi-même interdit');
    }

    if (Number(sender.balance) < Number(amount)) {
      throw new Error('Solde insuffisant');
    }

    // 💸 UPDATE BALANCES
    await client.query(
      'UPDATE users SET balance = balance - $1 WHERE id = $2',
      [amount, sender.id]
    );

    await client.query(
      'UPDATE users SET balance = balance + $1 WHERE id = $2',
      [amount, receiver.id]
    );

    const reference = 'TRX-' + Date.now();

    // 🧾 SAVE TRANSACTIONS
    await client.query(
      `INSERT INTO transactions (user_id, type, amount, title, reference)
       VALUES ($1, 'transfer', $2, $3, $4)`,
      [sender.id, amount, `Transfert vers ${receiver.phone}`, reference]
    );

    await client.query(
      `INSERT INTO transactions (user_id, type, amount, title, reference)
       VALUES ($1, 'credit_transfer', $2, $3, $4)`,
      [receiver.id, amount, `Reçu de ${sender.phone}`, reference]
    );

    const txResult = await client.query(
  `INSERT INTO transactions (sender_id, receiver_id, amount, type, reference, created_at)
   VALUES ($1, $2, $3, $4, $5, NOW())
   RETURNING id, amount, type, reference, created_at`,
  [sender.id, receiver.id, baseAmount, 'transfer', reference]
);
    await client.query('COMMIT');

  return res.json({
  success: true,
  message: 'Transfert réussi',

  reference, // 👈 mete li tou nan rasin

  data: {
    reference,
    amount,
    sender: sender.phone,
    receiver: receiver.phone,
  },

  receipt: {
    baseAmount,
    tcaAmount,
    commissionAmount,
    totalAmount: totalDebit,
    date: new Date(),
    date: txResult.rows[0].created_at,
}
  
});  
  
   


  } catch (error) {
    await client.query('ROLLBACK');

    return res.status(400).json({
      success: false,
      message: error.message,
    });

  } finally {
    client.release();
  }
});

module.exports = router;

router.post('/verify-number', auth, async (req, res) => {
  try {
    const { phone } = req.body;

    const result = await pool.query(
      'SELECT id, name, phone FROM users WHERE phone = $1',
      [phone]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Destinataire introuvable',
      });
    }

console.log('PIN BODY:', pin);
console.log('PIN DB:', sender.pin);
console.log('SENDER ID:', sender.id);

    return res.json({
      success: true,
      user: result.rows[0],
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      message: 'Erreur vérification numéro',
    });
  }
});

router.post('/manual-payment', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const { method, amount, reference } = req.body;

    // 1️⃣ VALIDATION
    if (!method || !amount || !reference) {
      return res.status(400).json({
        success: false,
        message: 'Champs manquants',
      });
    }

    // 2️⃣ INSERT DEMANDE PAYMENT
    const result = await pool.query(
      `INSERT INTO manual_payments 
       (user_id, method, amount, reference, status, created_at)
       VALUES ($1, $2, $3, $4, $5, NOW())
       RETURNING *`,
      [
        userId,
        method,
        Number(amount),
        reference,
        'pending',
      ]
    );

    console.log('NEW MANUAL PAYMENT:', result.rows[0]);

    // 3️⃣ REPONSE
    return res.json({
      success: true,
      message: 'Demande envoyée pour vérification ✅',
      payment: result.rows[0],
    });

  } catch (error) {
    console.error('MANUAL PAYMENT ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Erreur création paiement',
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

router.get('/admin/payments', async (req, res) => {
  const result = await pool.query(
    'SELECT * FROM manual_payments ORDER BY created_at DESC'
  );

  res.json(result.rows);
});

// GET TRANSACTIONS
router.get('/transactions', auth, async (req, res) => {
  try {
    const userId = req.userId;

    const result = await pool.query(
      `
      SELECT
        id,
        sender_id,
        receiver_id,
        amount,
        type,
        created_at,
        CASE
          WHEN receiver_id = $1 AND sender_id = $1 THEN 'self'
          WHEN receiver_id = $1 THEN 'credit'
          ELSE 'debit'
        END AS direction
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
  } catch (err) {
    console.error('TRANSACTIONS ERROR:', err);
    return res.status(500).json({
      success: false,
      message: 'Erreur récupération transactions',
    });
  }
});

router.post('/save-fcm-token', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({
        success: false,
        message: 'Token manquant',
      });
    }

    await pool.query(
      'UPDATE users SET fcm_token = $1 WHERE id = $2',
      [token, userId]
    );

    return res.json({
      success: true,
      message: 'FCM token enregistré',
    });
  } catch (error) {
    console.error('SAVE FCM TOKEN ERROR:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur sauvegarde token',
    });
  }
});


router.post('/admin/validate-payment', async (req, res) => {
  try {
    const { paymentId } = req.body;

    const paymentResult = await pool.query(
      'SELECT * FROM manual_payments WHERE id = $1',
      [paymentId]
    );

    if (paymentResult.rows.length === 0) {
      return res.json({
        success: false,
        message: 'Paiement introuvable',
      });
    }

    const payment = paymentResult.rows[0];

    if (payment.status === 'validated') {
      return res.json({
        success: false,
        message: 'Paiement déjà validé',
      });
    }

    await pool.query('BEGIN');

   const creditResult = await pool.query(
  `UPDATE users
   SET balance = COALESCE(balance, 0) + $1
   WHERE id = $2
   RETURNING id, phone, balance`,
  [Number(payment.amount), Number(payment.user_id)]
);

console.log('ADMIN CREDIT RESULT:', creditResult.rows);

if (creditResult.rows.length === 0) {
  await pool.query('ROLLBACK');
  return res.json({
    success: false,
    message: 'User introuvable, wallet non crédité',
  });
}
    await pool.query(
      `UPDATE manual_payments
       SET status = 'validated'
       WHERE id = $1`,
      [paymentId]
    );

    await pool.query(
      `INSERT INTO transactions (user_id, amount, type, description, created_at)
       VALUES ($1, $2, $3, $4, NOW())`,
      [
        payment.user_id,
        Number(payment.amount),
        'topup',
        `Paiement manuel validé - ${payment.method}`,
      ]
    );

    await pool.query('COMMIT');

    return res.json({
      success: true,
      message: 'Paiement validé et wallet crédité ✅',
      newBalance: creditResult.rows[0].balance,
    });
  } catch (error) {
    await pool.query('ROLLBACK').catch(() => {});
    console.error('VALIDATE PAYMENT ERROR:', error);
  
    console.log('UPDATE USER:', creditResult.rows);

    return res.status(500).json({
      success: false,
      message: 'Erreur validation paiement',
    });
  }
});

router.post('/admin/reject-payment', async (req, res) => {
  try {
    const { paymentId } = req.body;

    const result = await pool.query(
      'SELECT * FROM manual_payments WHERE id = $1',
      [paymentId]
    );

    if (result.rows.length === 0) {
      return res.json({ success: false, message: 'Paiement introuvable' });
    }

    const payment = result.rows[0];

    await pool.query(
      `UPDATE manual_payments
       SET status = $1
       WHERE id = $2`,
      ['rejected', paymentId]
    );

    await pool.query(
      `INSERT INTO notifications (user_id, title, message, type)
       VALUES ($1, $2, $3, $4)`,
      [
        payment.user_id,
        'Paiement rejeté ❌',
        `Votre paiement ${payment.method} de ${payment.amount} a été rejeté`,
        'payment_rejected',
      ]
    );

    const userRes = await pool.query(
      'SELECT fcm_token FROM users WHERE id = $1',
      [payment.user_id]
    );

    const user = userRes.rows[0];

    if (user && user.fcm_token) {
      await sendPushNotification(
        user.fcm_token,
        'Paiement rejeté ❌',
        `Votre paiement de ${payment.amount} a été refusé`
      );
    }

    return res.json({
      success: true,
      message: 'Paiement rejeté',
    });
  } catch (error) {
    console.error('REJECT PAYMENT ERROR:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur rejet paiement',
    });
  }
});


// TOPUP
router.post('/topup', auth, async (req, res) => {
  try {
    const userId = req.userId;
    const body = req.body || {};
    const { amount } = body;

    const parsedAmount = Number(amount);

    if (!parsedAmount || parsedAmount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Montant invalide',
      });
    }

    const userResult = await pool.query(
      'UPDATE users SET balance = balance + $1 WHERE id = $2 RETURNING balance',
      [parsedAmount, userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur introuvable',
      });
    }

    const txResult = await pool.query(
      `
      INSERT INTO transactions (sender_id, receiver_id, amount, type, created_at)
      VALUES ($1, $2, $3, $4, NOW())
      RETURNING id, sender_id, receiver_id, amount, type, created_at
      `,
      [userId, userId, parsedAmount, 'topup']
    );

    return res.json({
      success: true,
      message: 'Top up effectué avec succès',
      balance: Number(userResult.rows[0].balance),
      transaction: txResult.rows[0],
    });
  } catch (err) {
    console.error('TOPUP ERROR:', err);
    return res.status(500).json({
      success: false,
      message: 'Erreur topup serveur',
    });
  }
});

router.post('/manual-topup', auth, async (req, res) => {
  try {

    const { amount, method } = req.body;

    const userId = req.userId;

    const amountNumber = Number(amount);

    if (!amountNumber || amountNumber <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Montant invalide',
      });
    }

    await pool.query(
      `UPDATE users
       SET balance = COALESCE(balance, 0) + $1
       WHERE id = $2`,
      [amountNumber, userId]
    );

    const tx = await pool.query(
      `INSERT INTO transactions
      (user_id, amount, type, status, method, title, created_at)
      VALUES ($1, $2, 'topup', 'approved', $3, $4, NOW())
      RETURNING *`,
      [
        userId,
        amountNumber,
        method || 'moncash',
        'Cash In',
      ]
    );

    res.json({
      success: true,
      message: 'Wallet crédité avec succès',
      transaction: tx.rows[0],
    });

  } catch (err) {
    console.error('manual-topup error:', err);

    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});


router.post('/manual-topup', auth, async (req, res) => {
  const userId = req.userId;
  const { amount, method } = req.body;

  try {
    if (!amount || Number(amount) <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Montant invalide',
      });
    }

    const userId = req.userId;
const { amount, method } = req.body;
const amountNumber = Number(amount);

await pool.query(
  `UPDATE users
   SET balance = COALESCE(balance, 0) + $1
   WHERE id = $2`,
  [amountNumber, userId]
);

const tx = await pool.query(
  `INSERT INTO transactions
   (user_id, amount, type, status, method, title, description, created_at)
   VALUES ($1, $2, 'topup', 'approved', $3, $4, $5, NOW())
   RETURNING *`,
  [
    userId,
    amountNumber,
    method || 'moncash',
    'Cash In',
    `Recharge ${method || 'moncash'} créditée`,
  ]
);

res.json({
  success: true,
  message: 'Wallet crédité avec succès',
  transaction: tx.rows[0],
});
  } catch (err) {
    console.error('manual-topup error:', err);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

// SUBSCRIBE SERVICE (IPTV / INTERNET)
router.post('/subscribe', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const { service, plan, amount, pin } = req.body;

    if (!service || !plan || !amount || !pin) {
      return res.status(400).json({ success: false, message: 'Champs manquants' });
    }

    // 🔐 Verify PIN
    const userResult = await pool.query('SELECT pin, balance FROM users WHERE id = $1', [userId]);
    const user = userResult.rows[0];

    if (!user || String(user.pin).trim() !== String(pin).trim()) {
      return res.status(401).json({ success: false, message: 'PIN incorrect' });
    }

    if (parseFloat(user.balance) < parseFloat(amount)) {
      return res.status(400).json({ success: false, message: 'Solde insuffisant' });
    }

    // 💰 Débiter
   const debitResult = await pool.query(
  `UPDATE users
   SET balance = COALESCE(balance, 0) - $1
   WHERE id = $2
   RETURNING id, phone, balance`,
  [Number(amount), Number(userId)]
);

console.log('SUBSCRIBE DEBIT RESULT:', debitResult.rows);

if (debitResult.rows.length === 0) {
  return res.json({
    success: false,
    message: 'User introuvable, wallet non débité',
  });
}

    // 🧾 Transaction
    await pool.query(
      `INSERT INTO transactions (user_id, amount, type, description)
       VALUES ($1, $2, $3, $4)`,
      [userId, amount, 'subscription', `${service.toUpperCase()} - ${plan}`]
    );

console.log('REQ BODY:', req.body);
console.log('REQ USER ID:', req.userId);
console.log('USER FROM DB:', user);
console.log('PIN DB:', user.pin, typeof user.pin);
console.log('PIN APP:', pin, typeof pin);
console.log('COMPARE:', String(user.pin).trim() === String(pin).trim());

    return res.json({
      success: true,
      message: 'Abonnement activé',
    });

  } catch (error) {
    console.error('Subscribe error:', error);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.post('/subscribe', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const { service, plan, amount, pin } = req.body;

    console.log('SUBSCRIBE BODY:', req.body);
    console.log('SUBSCRIBE USER ID:', userId);

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'Utilisateur non connecté',
      });
    }

    if (!service || !plan || !amount || !pin) {
      return res.status(400).json({
        success: false,
        message: 'Champs manquants',
      });
    }

    const userResult = await pool.query(
      'SELECT id, pin, balance FROM users WHERE id = $1',
      [userId]
    );

    const user = userResult.rows[0];

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur introuvable',
      });
    }

    if (String(user.pin) !== String(pin)) {
      return res.status(401).json({
        success: false,
        message: 'PIN incorrect',
      });
    }

    const currentBalance = Number(user.balance);
    const price = Number(amount);

    if (currentBalance < price) {
      return res.status(400).json({
        success: false,
        message: 'Solde insuffisant',
      });
    }

    await pool.query('BEGIN');

    await pool.query(
      'UPDATE users SET balance = balance - $1 WHERE id = $2',
      [price, userId]
    );

    await pool.query(
      `INSERT INTO transactions 
       (user_id, amount, type, description, created_at)
       VALUES ($1, $2, $3, $4, NOW())`,
      [
        userId,
        price,
        'subscription',
        `${service.toUpperCase()} - ${plan}`,
      ]
    );

    await pool.query('COMMIT');

    return res.json({
      success: true,
      message: 'Abonnement activé avec succès ✅',
      newBalance: currentBalance - price,
    });
  } catch (error) {
    await pool.query('ROLLBACK').catch(() => {});
    console.error('SUBSCRIBE ERROR:', error);

    return res.status(500).json({
      success: false,
      message: 'Erreur serveur abonnement',
    });
  }
});

// PAY
router.post('/pay', auth, async (req, res) => {
  try {
    console.log('PAY BODY:', req.body);
    console.log('PAY USER ID:', req.userId);

    const userId = req.userId;
    const { amount, pin, description, merchantId } = req.body;

    

    if (!baseAmount || baseAmount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Montant invalide',
      });
    }

    const tcaRate = 0;
    const fgpayRate = 0.03;

   


const baseAmount = Number(amount);
const tcaAmount = 0;
const fgpayCommission = Math.round(baseAmount * 0.03 * 100) / 100; // 3%
const totalAmount = baseAmount + fgpayCommission;

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

    const user = userResult.rows[0];

    if (user.pin && pin && String(user.pin) !== String(pin)) {
      return res.status(401).json({
        success: false,
        message: 'PIN incorrect',
      });
    }

    if (Number(user.balance) < totalAmount) {
      return res.status(400).json({
        success: false,
        message: 'Solde insuffisant',
      });
    }

    let merchant = null;

    if (merchantId) {
      const merchantResult = await pool.query(
        'SELECT id, balance, name FROM users WHERE id = $1',
        [merchantId]
      );

      if (merchantResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Merchant introuvable',
        });
      }

      merchant = merchantResult.rows[0];
    }

    await pool.query('BEGIN');

    const debitResult = await pool.query(
      'UPDATE users SET balance = balance - $1 WHERE id = $2 RETURNING balance',
      [totalAmount, userId]
    );

    if (merchant) {
      await pool.query(
        'UPDATE users SET balance = balance + $1 WHERE id = $2',
        [baseAmount, merchant.id]
      );
    }

    const reference = `TX-${Date.now()}`;

// 💸 Débit user ak commission FGPay
await pool.query(
  'UPDATE users SET balance = balance - $1 WHERE id = $2',
  [totalAmount, userId]
);

// 💰 Crédit merchant sèlman montant de base la
if (merchantId) {
  await pool.query(
    'UPDATE users SET balance = balance + $1 WHERE id = $2',
    [baseAmount, merchantId]
  );
}

    const txResult = await pool.query(
      
      `INSERT INTO transactions
   (sender_id, receiver_id, amount, base_amount, tca_amount, commission_amount, total_amount, type, title, 
   description, reference, status)
   VALUES ($1,$2,$3,$4,$5,$6,$7,'payment','Paiement FGPay','Paiement avec commission FGPay',$8,'approved')`,
      
      [
        userId,
        merchant ? merchant.id : userId,
        baseAmount,
        'qr_payment',
        description || 'Paiement QR',
        0,
        fgpayCommission,
        totalAmount,
        reference,
      ]
    );

    await pool.query('COMMIT');

    return res.json({
      success: true,
      message: 'Paiement QR réussi',
      balance: Number(debitResult.rows[0].balance),
      transaction: {
        ...txResult.rows[0],
        merchantName: merchant?.name || 'FGPay Merchant',
        date: txResult.rows[0].created_at,
      },
    });
  } catch (err) {
    try {
      await pool.query('ROLLBACK');
    } catch (_) {}

    console.error('PAY ERROR:', err);

    return res.status(500).json({
      success: false,
      message: 'Erreur pay serveur',
      error: err.message,
    });
  }
});

router.post('/admin/validate-payment', async (req, res) => {
  try {
    const { paymentId } = req.body;

    const result = await pool.query(
      'SELECT * FROM manual_payments WHERE id = $1',
      [paymentId]
    );

    if (result.rows.length === 0) {
      return res.json({ success: false, message: 'Paiement introuvable' });
    }

    const payment = result.rows[0];

    if (payment.status === 'validated') {
      return res.json({ success: false, message: 'Paiement déjà validé' });
    }

    await pool.query('BEGIN');

    await pool.query(
      'UPDATE users SET balance = balance + $1 WHERE id = $2',
      [payment.amount, payment.user_id]
    );

    await pool.query(
      "UPDATE manual_payments SET status = 'validated' WHERE id = $1",
      [paymentId]
    );

    await pool.query(
      `INSERT INTO transactions (user_id, amount, type, description, created_at)
       VALUES ($1, $2, 'topup', $3, NOW())`,
      [payment.user_id, payment.amount, `Paiement manuel validé - ${payment.method}`]
    );

    await pool.query('COMMIT');

    return res.json({
      success: true,
      message: 'Paiement validé et wallet crédité ✅',
    });
  } catch (error) {
    await pool.query('ROLLBACK').catch(() => {});
    console.error('VALIDATE PAYMENT ERROR:', error);
    return res.status(500).json({ success: false, message: 'Erreur validation paiement' });
  }
});


// TRANSFER
router.post('/transfer', auth, async (req, res) => {
  try {
    const userId = req.userId;
    const body = req.body || {};
    const { receiverPhone, amount, pin } = body;

    const parsedAmount = Number(amount);

    if (!receiverPhone || !parsedAmount || parsedAmount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Paramètres invalides',
      });
    }
const baseAmount = parsedAmount;
const tcaAmount = 0;

const commissionRate = 0.02;
const minCommission = 10;

const commissionAmount = Number(
  Math.max(baseAmount * commissionRate, minCommission).toFixed(2)
);

const totalDebit = Number((baseAmount + commissionAmount).toFixed(2));

    const senderResult = await pool.query(
      'SELECT id, balance, pin, name, phone FROM users WHERE id = $1',
      [userId]
    );

    if (senderResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Expéditeur introuvable',
      });
    }

    const sender = senderResult.rows[0];

    if (sender.pin && pin && String(sender.pin) !== String(pin)) {
      return res.status(401).json({
        success: false,
        message: 'PIN incorrect',
      });
    }

    if (Number(sender.balance) < parsedAmount) {
      return res.status(400).json({
        success: false,
        message: 'Solde insuffisant',
      });
    }

    const receiverResult = await pool.query(
      'SELECT id, name, phone, balance FROM users WHERE phone = $1',
      [receiverPhone]
    );

    if (receiverResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Destinataire introuvable',
      });
    }

    const receiver = receiverResult.rows[0];

    if (Number(receiver.id) === Number(userId)) {
      return res.status(400).json({
        success: false,
        message: 'Transfert vers soi-même interdit',
      });
    }

   const updateResult = await pool.query(
  'UPDATE users SET balance = balance - $1 WHERE id = $2 RETURNING balance',
  [parsedAmount, userId]
);


    await pool.query(
      'UPDATE users SET balance = balance + $1 WHERE id = $2',
      [parsedAmount, receiver.id]
    );

    const txResult = await pool.query(
      `
      INSERT INTO transactions (sender_id, receiver_id, amount, type, created_at)
      VALUES ($1, $2, $3, $4, NOW())
      RETURNING id, sender_id, receiver_id, amount, type, created_at
      `,
      [userId, receiver.id, parsedAmount, 'transfer']
    );

    const newSenderBalance = await pool.query(
      'SELECT balance FROM users WHERE id = $1',
      [userId]
    );

    return res.json({
      success: true,
      message: 'Transfert effectué avec succès',
      balance: Number(newSenderBalance.rows[0].balance),
      reference: `TRF-${Date.now()}`,
      transaction: txResult.rows[0],
      receiver: {
        id: receiver.id,
        name: receiver.name,
        phone: receiver.phone,
      },

      receipt: {
  baseAmount,
  tcaAmount,
  commissionAmount,
  totalAmount: totalDebit,
  date: txResult.rows[0].created_at,
}
    });
  } catch (err) {
    console.error('TRANSFER ERROR:', err);
    return res.status(500).json({
      success: false,
      message: 'Erreur transfer serveur',
    });
  }
});

module.exports = router;