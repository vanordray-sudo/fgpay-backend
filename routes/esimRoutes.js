const express = require('express');
const pool = require('../db');
const auth = require('../middleware/auth');
const { createEsim } = require('../services/esimProviderService');
const { processOrder } = require('../services/esimGoService');



const router = express.Router();

function getUserId(req) {
  return req.userId || req.user?.id;
}

// GET /api/esim/plans
router.get('/plans', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT * FROM esim_plans WHERE is_active = true ORDER BY id ASC`
    );

    return res.json({
      success: true,
      plans: result.rows,
    });
  } catch (error) {
    console.error('GET /api/esim/plans error:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur chargement plans eSIM',
      error: error.message,
    });
  }
});

// ✅ Handler PRO pou /buy ak /purchase
async function purchaseEsimHandler(req, res) {
  const client = await pool.connect();

  try {
    const userId = getUserId(req);
    const { planId, pin } = req.body || {};

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'Utilisateur non authentifié',
      });
    }

    if (!planId) {
      return res.status(400).json({
        success: false,
        message: 'planId requis',
      });
    }

    if (!pin) {
      return res.status(400).json({
        success: false,
        message: 'PIN requis',
      });
    }

    await client.query('BEGIN');

    // 🔐 Lock user balance
    const userResult = await client.query(
      `SELECT id, phone, balance, pin FROM users WHERE id = $1 FOR UPDATE`,
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

    // 📦 Get active plan
    const planResult = await client.query(
      `SELECT * FROM esim_plans WHERE id = $1 AND is_active = true LIMIT 1`,
      [planId]
    );

    if (planResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        message: 'Plan eSIM introuvable',
      });
    }

    const plan = planResult.rows[0];

    const baseAmount = Number(plan.price);
    const tcaRate = 0.10;
    const fgpayRate = 0.02;

    const tcaAmount = Number((baseAmount * tcaRate).toFixed(2));
    const fgpayCommission = Number((baseAmount * fgpayRate).toFixed(2));
    const totalAmount = Number(
      (baseAmount + tcaAmount + fgpayCommission).toFixed(2)
    );

    if (Number(user.balance) < totalAmount) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Solde insuffisant',
      });
    }

    // 🧾 Create order pending
    const orderResult = await client.query(
      `
      INSERT INTO esim_orders (
        user_id,
        plan_id,
        amount,
        currency,
        status,
        payment_method
      )
      VALUES ($1, $2, $3, $4, 'pending_provider', 'wallet')
      RETURNING *
      `,
      [userId, plan.id, totalAmount, plan.currency || 'USD']
    );

    const order = orderResult.rows[0];

    // 🌍 Call provider APRÈS PIN + SOLDE OK
    const provider = await processOrder({
  bundleName:
    plan.provider_plan_id ||
    plan.provider_plan_code ||
    plan.provider_code ||
    plan.name,
  quantity: 1,
});

    // 💳 Debit wallet
    const newBalance = Number((Number(user.balance) - totalAmount).toFixed(2));

    await client.query(
      `UPDATE users SET balance = $1 WHERE id = $2`,
      [newBalance, userId]
    );

    // 💾 Save eSIM line
    const lineResult = await client.query(
      `
      INSERT INTO esim_lines (
        order_id,
        user_id,
        plan_id,
        provider_iccid,
        provider_matching_id,
        smdp_address,
        activation_code,
        qr_code_url,
        manual_code,
        status,
        provider_response
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
      RETURNING *
      `,
      [
        order.id,
        userId,
        plan.id,
        provider.iccid || null,
        provider.matchingId || null,
        provider.smdpAddress || null,
        provider.activationCode || null,
        provider.qrCodeUrl || provider.qrCode || null,
        provider.manualCode || null,
        provider.status || 'active',
        JSON.stringify(provider.raw || provider),
      ]
    );

    // ✅ Update order completed
    await client.query(
      `UPDATE esim_orders SET status = 'completed' WHERE id = $1`,
      [order.id]
    );

    // 🧾 Transaction wallet
    await client.query(
      `
      INSERT INTO transactions (
        user_id,
        type,
        amount,
        base_amount,
        tca_amount,
        total_amount,
        title,
        description,
        reference,
        created_at
      )
      VALUES ($1, 'payment', $2, $3, $4, $5, $6, $7, $8, NOW())
      `,
      [
        userId,
        totalAmount,
        baseAmount,
        tcaAmount,
        totalAmount,
        'Achat eSIM',
        `Achat du plan ${plan.name} | Base: ${baseAmount} ${plan.currency || 'USD'} | TCA: ${tcaAmount} ${plan.currency || 'USD'} | FGPay: ${fgpayCommission} ${plan.currency || 'USD'}`,
        `ESIM-${order.id}`,
      ]
    );

    await client.query('COMMIT');

    return res.json({
      success: true,
      message: 'eSIM achetée avec succès',
      balance: newBalance,
      pricing: {
        baseAmount,
        tcaAmount,
        fgpayCommission,
        totalAmount,
        currency: plan.currency || 'USD',
      },
      order: {
        ...order,
        status: 'completed',
      },
      line: lineResult.rows[0],
      esim: lineResult.rows[0],
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('POST /api/esim purchase error:', error);

console.error('❌ ESIM PROVIDER ERROR:', {
  status: error.response?.status,
  data: error.response?.data,
  message: error.message,
});
    return res.status(500).json({
      success: false,
      message: 'Erreur achat eSIM',
      error: error.message,
    });
  } finally {
    client.release();
  }
}

// POST /api/esim/buy
router.post('/buy', auth, purchaseEsimHandler);
 

module.exports = router;
// POST /api/esim/purchase
router.post('/purchase', auth, purchaseEsimHandler);

// GET /api/esim/my-lines
router.get('/my-lines', auth, async (req, res) => {
  try {
    const userId = getUserId(req);

    const result = await pool.query(
      `
      SELECT
        l.*,
        p.name AS plan_name,
        p.country,
        p.data_label,
        p.validity_days,
        p.price,
        p.currency
      FROM esim_lines l
      JOIN esim_plans p ON p.id = l.plan_id
      WHERE l.user_id = $1
      ORDER BY l.created_at DESC
      `,
      [userId]
    );

    return res.json({
      success: true,
      lines: result.rows,
    });
 } catch (error) {
  console.error('❌ ESIM PROVIDER ERROR FULL:', {
    status: error.response?.status,
    data: error.response?.data,
    message: error.message,
  });

  return res.status(500).json({
    success: false,
    message: 'Erreur achat eSIM',
    error: error.response?.data || error.message,
  });
}
});



// GET /api/esim/my
router.get('/my', auth, async (req, res) => {
  try {
    const userId = getUserId(req);

    const result = await pool.query(
      `
      SELECT
        l.*,
        p.name AS plan_name,
        p.country,
        p.data_label,
        p.validity_days,
        p.price,
        p.currency
      FROM esim_lines l
      JOIN esim_plans p ON p.id = l.plan_id
      WHERE l.user_id = $1
      ORDER BY l.created_at DESC
      `,
      [userId]
    );

    return res.json({
      success: true,
      esims: result.rows,
      lines: result.rows,
    });
  } catch (error) {
    console.error('GET /api/esim/my error:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur chargement eSIM utilisateur',
      error: error.message,
    });
  }
});

// GET /api/esim/line/:id
router.get('/line/:id', auth, async (req, res) => {
  try {
    const userId = getUserId(req);

    const result = await pool.query(
      `
      SELECT
        l.*,
        p.name AS plan_name,
        p.country,
        p.data_label,
        p.validity_days,
        p.price,
        p.currency
      FROM esim_lines l
      JOIN esim_plans p ON p.id = l.plan_id
      WHERE l.id = $1 AND l.user_id = $2
      LIMIT 1
      `,
      [req.params.id, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Ligne eSIM introuvable',
      });
    }

    return res.json({
      success: true,
      line: result.rows[0],
    });
  } catch (error) {
   
  }
});

module.exports = router;