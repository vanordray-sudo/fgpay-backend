const express = require('express');
const router = express.Router();
const pool = require('../db');
const auth = require('../middleware/auth');

router.get('/balance', auth, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, email, balance FROM public.users WHERE id = $1',
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Failed to load balance' });
  }
});

router.get('/transactions', auth, async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await pool.query(
      `SELECT 
          t.id,
          s.email AS sender,
          r.email AS receiver,
          t.amount,
          t.type,
          t.created_at
       FROM public.transactions t
       LEFT JOIN public.users s ON t.sender_id = s.id
       LEFT JOIN public.users r ON t.receiver_id = r.id
       WHERE t.sender_id = $1 OR t.receiver_id = $1
       ORDER BY t.created_at DESC, t.id DESC`,
      [userId]
    );

    res.json(result.rows);
  } catch (err) {
    console.error('Transactions route error:', err);
    res.status(500).json({ message: 'Failed to load transactions' });
  }
});

router.get('/profile', auth, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, email, balance FROM public.users WHERE id = $1',
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

router.post('/transfer', auth, async (req, res) => {
  console.log('USER ID:', req.user.id);
  console.log('BODY:', req.body);

  const { receiverEmail, amount } = req.body;
  const senderId = req.user.id;
  const transferAmount = Number(amount);

  if (!receiverEmail || !amount) {
    return res.status(400).json({ message: 'receiverEmail and amount are required' });
  }

  if (isNaN(transferAmount) || transferAmount <= 0) {
    return res.status(400).json({ message: 'Amount must be greater than 0' });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const senderResult = await client.query(
      'SELECT id, email, balance FROM public.users WHERE id = $1 FOR UPDATE',
      [senderId]
    );

    if (senderResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ message: 'Sender not found' });
    }

    const receiverResult = await client.query(
      'SELECT id, email, balance FROM public.users WHERE email = $1 FOR UPDATE',
      [receiverEmail]
    );

    if (receiverResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ message: 'Receiver not found' });
    }

    const sender = senderResult.rows[0];
    const receiver = receiverResult.rows[0];

    if (sender.id === receiver.id) {
      await client.query('ROLLBACK');
      return res.status(400).json({ message: 'You cannot transfer to yourself' });
    }

    const senderBalance = Number(sender.balance);

    if (senderBalance < transferAmount) {
      await client.query('ROLLBACK');
      return res.status(400).json({ message: 'Insufficient balance' });
    }

    await client.query(
      'UPDATE public.users SET balance = balance - $1 WHERE id = $2',
      [transferAmount, sender.id]
    );

    await client.query(
      'UPDATE public.users SET balance = balance + $1 WHERE id = $2',
      [transferAmount, receiver.id]
    );

    await client.query(
      `INSERT INTO public.transactions (sender_id, receiver_id, amount, type)
       VALUES ($1, $2, $3, $4)`,
      [sender.id, receiver.id, transferAmount, 'transfer']
    );

    await client.query('COMMIT');

    const updatedSender = await client.query(
      'SELECT id, email, balance FROM public.users WHERE id = $1',
      [sender.id]
    );

    const updatedReceiver = await client.query(
      'SELECT id, email, balance FROM public.users WHERE id = $1',
      [receiver.id]
    );

    res.json({
      message: 'Transfer successful',
      sender: updatedSender.rows[0],
      receiver: updatedReceiver.rows[0],
      amount: transferAmount
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    res.status(500).json({ message: 'Transfer failed' });
  } finally {
    client.release();
  }
});

module.exports = router;