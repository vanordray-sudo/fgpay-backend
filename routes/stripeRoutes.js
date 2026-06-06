const express = require('express');
const Stripe = require('stripe');
const pool = require('../db');

const router = express.Router();
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

router.post('/create-checkout-session', async (req, res) => {
  try {
    const body = req.body || {};
    console.log('STRIPE BODY =', body);

    const { serviceName, amount, currency, userId } = body;
    const parsedAmount = Number(amount);
    const parsedUserId = Number(userId);

    if (!serviceName || !parsedAmount || parsedAmount <= 0 || !parsedUserId) {
      return res.status(400).json({
        success: false,
        message: 'serviceName, amount et userId valides sont requis',
      });
    }

    const userCheck = await pool.query(
      'SELECT id FROM users WHERE id = $1 LIMIT 1',
      [parsedUserId]
    );

    if (userCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur introuvable avant création session Stripe',
      });
    }

    const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:64505';
    const finalCurrency = (currency || 'eur').toLowerCase();

   const session = await stripe.checkout.sessions.create({
  mode: 'payment',
  payment_method_types: ['card'],

  client_reference_id: String(parsedUserId),

  metadata: {
    userId: String(parsedUserId),
    amount: String(parsedAmount),
    serviceName: String(serviceName),
  },

  line_items: [
    {
      price_data: {
        currency: finalCurrency,
        product_data: {
          name: serviceName,
        },
        unit_amount: Math.round(parsedAmount * 100),
      },
      quantity: 1,
    },
  ],

  success_url: `${frontendUrl}/#/payment-success?session_id={CHECKOUT_SESSION_ID}`,
  cancel_url: `${frontendUrl}/#/payment-cancel`,
});

    return res.json({
      success: true,
      checkoutUrl: session.url,
      sessionId: session.id,
    });
  } catch (error) {
    console.error('STRIPE CREATE SESSION ERROR:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Erreur création session Stripe',
      error: error.message,
    });
  }
});

router.post('/confirm-checkout-session', async (req, res) => {
  try {
    const { sessionId } = req.body || {};

    if (!sessionId) {
      return res.status(400).json({
        success: false,
        message: 'sessionId requis',
      });
    }

    const session = await stripe.checkout.sessions.retrieve(sessionId);

    if (!session) {
      return res.status(404).json({
        success: false,
        message: 'Session Stripe introuvable',
      });
    }

    if (session.payment_status !== 'paid') {
      return res.status(400).json({
        success: false,
        message: 'Paiement non confirmé',
        status: session.payment_status,
      });
    }

    const userId = Number(session.metadata?.userId || session.client_reference_id);
    const amount = Number(session.metadata?.amount || 0);

    if (!userId || !amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Metadata Stripe invalide',
      });
    }

    const existingTx = await pool.query(
      `SELECT id FROM transactions WHERE reference = $1 LIMIT 1`,
      [session.id]
    );

    if (existingTx.rows.length > 0) {
      const balanceResult = await pool.query(
        'SELECT balance FROM users WHERE id = $1',
        [userId]
      );

      return res.json({
        success: true,
        message: 'Paiement déjà traité',
        balance: Number(balanceResult.rows[0]?.balance || 0),
        alreadyProcessed: true,
      });
    }

    await pool.query('BEGIN');

    const userResult = await pool.query(
      'UPDATE users SET balance = balance + $1 WHERE id = $2 RETURNING balance',
      [amount, userId]
    );

    if (userResult.rows.length === 0) {
      await pool.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        message: 'Utilisateur introuvable',
      });
    }

    const txResult = await pool.query(
      `
      INSERT INTO transactions (
        sender_id,
        receiver_id,
        amount,
        type,
        description,
        reference,
        created_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, NOW())
      RETURNING *
      `,
      [
        userId,
        userId,
        amount,
        'topup',
        'Recharge Stripe',
        session.id,
      ]
    );

    await pool.query('COMMIT');

    return res.json({
      success: true,
      message: 'Wallet crédité avec succès',
      balance: Number(userResult.rows[0].balance),
      transaction: txResult.rows[0],
      sessionStatus: session.payment_status,
    });
  } catch (error) {
    try {
      await pool.query('ROLLBACK');
    } catch (_) {}

    console.error('STRIPE CONFIRM SESSION ERROR:', error.message);

    return res.status(500).json({
      success: false,
      message: 'Erreur confirmation session Stripe',
      error: error.message,
    });
  }
});

module.exports = router;