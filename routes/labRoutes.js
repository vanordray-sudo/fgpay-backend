const express = require('express');
const router = express.Router();
const pool = require('../db');
const auth = require('../middleware/auth');

// CREATE LAB
router.post('/', auth, async (req, res) => {
  try {
    const { name, phone, address } = req.body;

    if (!name) {
      return res.status(400).json({ success: false, message: 'Nom laboratoire requis' });
    }

    const result = await pool.query(
      `INSERT INTO laboratories (name, phone, address)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [name, phone || null, address || null]
    );

    res.json({ success: true, laboratory: result.rows[0] });
  } catch (err) {
    console.error('CREATE LAB ERROR:', err);
    res.status(500).json({ success: false, message: 'Erreur création laboratoire' });
  }
});

// LIST LABS
router.get('/', auth, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT * FROM laboratories
       WHERE is_active = true
       ORDER BY created_at DESC`
    );

    res.json({ success: true, laboratories: result.rows });
  } catch (err) {
    console.error('LIST LABS ERROR:', err);
    res.status(500).json({ success: false, message: 'Erreur liste laboratoires' });
  }
});

// CREATE LAB ORDER
router.post('/orders', auth, async (req, res) => {
  try {
    const { patientId, laboratoryId, testName, amount } = req.body;

    if (!patientId || !laboratoryId || !testName) {
      return res.status(400).json({ success: false, message: 'Champs manquants' });
    }

    const result = await pool.query(
      `INSERT INTO lab_orders (patient_id, laboratory_id, test_name, amount)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [patientId, laboratoryId, testName, amount || 0]
    );

    res.json({ success: true, order: result.rows[0] });
  } catch (err) {
    console.error('CREATE LAB ORDER ERROR:', err);
    res.status(500).json({ success: false, message: 'Erreur création demande labo' });
  }
});

// PATIENT ORDERS
router.get('/orders/patient/:patientId', auth, async (req, res) => {
  try {
    const { patientId } = req.params;

    const result = await pool.query(
      `SELECT lo.*, l.name AS laboratory_name, l.address AS laboratory_address
       FROM lab_orders lo
       JOIN laboratories l ON l.id = lo.laboratory_id
       WHERE lo.patient_id = $1
       ORDER BY lo.created_at DESC`,
      [patientId]
    );

    res.json({ success: true, orders: result.rows });
  } catch (err) {
    console.error('PATIENT LAB ORDERS ERROR:', err);
    res.status(500).json({ success: false, message: 'Erreur historique labo' });
  }
});

// ADD RESULT
router.put('/orders/:id/result', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const { resultText, resultFileUrl } = req.body;

    const result = await pool.query(
      `UPDATE lab_orders
       SET result_text = $1,
           result_file_url = $2,
           status = 'completed',
           completed_at = NOW()
       WHERE id = $3
       RETURNING *`,
      [resultText || null, resultFileUrl || null, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Demande introuvable' });
    }

    res.json({ success: true, order: result.rows[0] });
  } catch (err) {
    console.error('ADD LAB RESULT ERROR:', err);
    res.status(500).json({ success: false, message: 'Erreur ajout résultat' });
  }
});

// PAY LAB ORDER WITH FGPAY WALLET
router.post('/orders/:id/pay', auth, async (req, res) => {
  const userId = req.userId || req.user?.id;
  const { id } = req.params;
  const { pin } = req.body;

  if (!userId) {
    return res.status(401).json({ success: false, message: 'Session invalide' });
  }

  if (!pin || String(pin).length !== 6) {
    return res.status(400).json({ success: false, message: 'PIN invalide' });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const userResult = await client.query(
      `SELECT id, balance, pin FROM users WHERE id = $1 FOR UPDATE`,
      [userId]
    );

    const user = userResult.rows[0];

    if (!user) throw new Error('Utilisateur introuvable');

    if (String(user.pin) !== String(pin)) {
      throw new Error('PIN incorrect');
    }

    const orderResult = await client.query(
      `SELECT * FROM lab_orders WHERE id = $1 FOR UPDATE`,
      [id]
    );

    const order = orderResult.rows[0];

    if (!order) throw new Error('Demande labo introuvable');

    if (order.payment_status === 'paid') {
      throw new Error('Cette demande est déjà payée');
    }

    const amount = Number(order.amount || 0);

    if (Number(user.balance) < amount) {
      throw new Error('Solde insuffisant');
    }

    await client.query(
      `UPDATE users SET balance = balance - $1 WHERE id = $2`,
      [amount, userId]
    );

    await client.query(
      `UPDATE lab_orders
       SET payment_status = 'paid',
           status = CASE WHEN status = 'pending' THEN 'accepted' ELSE status END
       WHERE id = $1`,
      [id]
    );

    const reference = `LAB${Date.now()}`;

    await client.query(
      `INSERT INTO transactions (user_id, type, amount, title, reference, created_at)
       VALUES ($1, 'health_lab_payment', $2, $3, $4, NOW())`,
      [userId, amount, `Paiement test laboratoire #${id}`, reference]
    );

    await client.query('COMMIT');

    res.json({
      success: true,
      message: 'Paiement laboratoire réussi ✅',
      reference,
      amount,
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('PAY LAB ORDER ERROR:', err.message);

    res.status(400).json({
      success: false,
      message: err.message,
    });
  } finally {
    client.release();
  }
});

module.exports = router;