const express = require('express');
const router = express.Router();
const pool = require('../db');
const authMiddleware = require('../middleware/auth');

// ✅ TOPUP ROUTE
router.post('/topup', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const { amount } = req.body;

    if (!amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Montant invalide',
      });
    }

    // 🔥 AJOUTE LAJAN NAN BALANCE
    router.get('/balance', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;

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

    res.json({
      success: true,
      balance: Number(result.rows[0].balance || 0),
    });
  } catch (err) {
    console.error('BALANCE ERROR:', err);
    res.status(500).json({
      success: false,
      message: 'Erreur récupération balance',
    });
  }
});
    
    await pool.query(
      'UPDATE users SET balance = balance + $1 WHERE id = $2',
      [amount, userId]
    );

    // 🔥 AJOUTE TRANSACTION
    router.get('/transactions', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await pool.query(
      `SELECT id, sender_id, receiver_id, amount, type, created_at
       FROM transactions
       WHERE sender_id = $1 OR receiver_id = $1
       ORDER BY created_at DESC`,
      [userId]
    );

    const formatted = result.rows.map((tx) => ({
      ...tx,
      date: tx.created_at,
      title: tx.type === 'topup'
          ? 'Cash In'
          : tx.type === 'payment'
              ? 'Payment'
              : 'Transaction',
      direction: tx.receiver_id === userId && tx.sender_id !== userId
          ? 'received'
          : 'sent',
    }));

    res.json(formatted);
  } catch (err) {
    console.error('TRANSACTIONS ERROR:', err);
    res.status(500).json({
      success: false,
      message: 'Erreur récupération transactions',
    });
  }
});
    
    await pool.query(
      `INSERT INTO transactions (sender_id, receiver_id, amount, type)
       VALUES ($1, $1, $2, 'topup')`,
      [userId, amount]
    );

    res.json({
      success: true,
      message: 'Top up réussi',
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

module.exports = router;

router.post('/topup', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const { amount } = req.body;

    if (!amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Montant invalide',
      });
    }

    // 🔥 AJOUTE LAJAN NAN BALANCE
    await pool.query(
      'UPDATE users SET balance = balance + $1 WHERE id = $2',
      [amount, userId]
    );

    // 🔥 AJOUTE TRANSACTION
    await pool.query(
      `INSERT INTO transactions (sender_id, receiver_id, amount, type)
       VALUES ($1, $1, $2, 'topup')`,
      [userId, amount]
    );

    res.json({
      success: true,
      message: 'Top up réussi',
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

router.post('/transfer', authMiddleware, async (req, res) => {
  try {
    const { receiverPhone, amount, pin } = req.body;
    const senderId = req.user.id;

    const receiver = await pool.query(
      'SELECT * FROM users WHERE phone = $1',
      [receiverPhone]
    );

    if (receiver.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Destinataire introuvable',
      });
    }

    const receiverId = receiver.rows[0].id;

    // Deduct sender
    await pool.query(
      'UPDATE users SET balance = balance - $1 WHERE id = $2',
      [amount, senderId]
    );

    // Add receiver
    await pool.query(
      'UPDATE users SET balance = balance + $1 WHERE id = $2',
      [amount, receiverId]
    );

    // Insert transaction
    await pool.query(
      `INSERT INTO transactions (sender_id, receiver_id, amount, type)
       VALUES ($1, $2, $3, 'transfer')`,
      [senderId, receiverId, amount]
    );

    res.json({
      success: true,
      message: 'Transfert réussi',
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      message: 'Erreur transfert',
    });
  }
});

router.post('/pay', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const { amount, pin, description } = req.body;

    if (!amount || Number(amount) <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Montant invalide',
      });
    }

    const userResult = await pool.query(
      'SELECT id, name, phone, balance, pin, address, nif FROM users WHERE id = $1',
      [userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur introuvable',
      });
    }

    const user = userResult.rows[0];

    if (!pin || user.pin !== pin) {
      return res.status(401).json({
        success: false,
        message: 'PIN incorrect',
      });
    }

    if (Number(user.balance) < Number(amount)) {
      return res.status(400).json({
        success: false,
        message: 'Solde insuffisant',
      });
    }

    await pool.query(
      'UPDATE users SET balance = balance - $1 WHERE id = $2',
      [amount, userId]
    );

    await pool.query(
      `INSERT INTO transactions (sender_id, receiver_id, amount, type)
       VALUES ($1, $1, $2, 'payment')`,
      [userId, amount]
    );

    const updatedUser = await pool.query(
      'SELECT balance FROM users WHERE id = $1',
      [userId]
    );

    res.json({
      success: true,
      message: 'Paiement réussi',
      balance: Number(updatedUser.rows[0].balance || 0),
      transaction: {
        type: 'payment',
        amount: Number(amount),
        date: new Date(),
        title: description && description.trim() !== ''
          ? description
          : 'Payment',
        user: {
          name: user.name,
          phone: user.phone,
          address: user.address,
          nif: user.nif,
        },
      },
    });
  } catch (err) {
    console.error('PAY ERROR:', err);
    res.status(500).json({
      success: false,
      message: 'Erreur paiement',
    });
  }
});