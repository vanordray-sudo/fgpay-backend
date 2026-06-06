const express = require('express');
const crypto = require('crypto');
const pool = require('../db');
const auth = require('../middleware/auth');
const { addHotspotUser } = require('../services/mikrotikService');

const router = express.Router();

/**
 * GET /api/internet/plans
 */
router.get('/plans', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, name, code, data_limit_gb, speed_limit_mbps, validity_days, price
       FROM internet_plans
       WHERE is_active = TRUE
       ORDER BY price ASC`
    );

    res.json({
      success: true,
      plans: result.rows,
    });
  } catch (e) {
    console.error('Erreur GET /plans:', e);
    res.status(500).json({
      success: false,
      message: 'Erreur récupération plans internet',
    });
  }
});

/**
 * GET /api/internet/my-subscription
 */
router.get('/my-subscription', auth, async (req, res) => {
  try {
    const userId = req.userId;

    const result = await pool.query(
      `SELECT 
         s.id,
         s.user_id,
         s.plan_id,
         s.antenna_id,
         s.zone_id,
         s.username_hotspot,
         s.password_hotspot,
         s.data_allocated_gb,
         s.data_used_gb,
         s.data_remaining_gb,
         s.speed_limit_mbps,
         s.start_date,
         s.expiry_date,
         s.status,
         s.auto_renew,
         p.name AS plan_name,
         p.code AS plan_code,
         z.name AS zone_name,
         a.name AS antenna_name
       FROM internet_subscriptions s
       JOIN internet_plans p ON s.plan_id = p.id
       LEFT JOIN zones z ON s.zone_id = z.id
       LEFT JOIN antennas a ON s.antenna_id = a.id
       WHERE s.user_id = $1
       ORDER BY s.created_at DESC
       LIMIT 1`,
      [userId]
    );

    res.json({
      success: true,
      subscription: result.rows[0] || null,
    });
  } catch (e) {
    console.error('Erreur GET /my-subscription:', e);
    res.status(500).json({
      success: false,
      message: 'Erreur récupération abonnement',
    });
  }
});

/**
 * POST /api/internet/buy-plan
 * Body: { planId }
 */
router.post('/buy-plan', auth, async (req, res) => {
  const client = await pool.connect();

  try {
    const userId = req.userId;
    const { planId } = req.body;

    if (!planId) {
      return res.status(400).json({
        success: false,
        message: 'planId requis',
      });
    }

    await client.query('BEGIN');

    const userResult = await client.query(
      'SELECT id, phone, balance FROM users WHERE id = $1 FOR UPDATE',
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

    const planResult = await client.query(
      `SELECT id, name, code, data_limit_gb, speed_limit_mbps, validity_days, price
       FROM internet_plans
       WHERE id = $1 AND is_active = TRUE`,
      [planId]
    );

    if (planResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        message: 'Plan introuvable',
      });
    }

    const plan = planResult.rows[0];

    if (Number(user.balance) < Number(plan.price)) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Solde insuffisant',
      });
    }

    const existingSubResult = await client.query(
      `SELECT id FROM internet_subscriptions
       WHERE user_id = $1 AND status = 'active'
       ORDER BY created_at DESC
       LIMIT 1`,
      [userId]
    );

    if (existingSubResult.rows.length > 0) {
      await client.query(
        `UPDATE internet_subscriptions
         SET status = 'expired'
         WHERE id = $1`,
        [existingSubResult.rows[0].id]
      );
    }

    const newBalance = Number(user.balance) - Number(plan.price);

    await client.query(
      'UPDATE users SET balance = $1 WHERE id = $2',
      [newBalance, userId]
    );

    const usernameHotspot = user.phone || `user${userId}`;
    const passwordHotspot = crypto.randomBytes(4).toString('hex');
    const expiryResult = await client.query(
      `SELECT CURRENT_TIMESTAMP + ($1 || ' days')::interval AS expiry_date`,
      [plan.validity_days]
    );

    const expiryDate = expiryResult.rows[0].expiry_date;

    const subscriptionResult = await client.query(
      `INSERT INTO internet_subscriptions (
         user_id,
         plan_id,
         username_hotspot,
         password_hotspot,
         data_allocated_gb,
         data_used_gb,
         data_remaining_gb,
         speed_limit_mbps,
         start_date,
         expiry_date,
         status,
         auto_renew
       )
       VALUES ($1,$2,$3,$4,$5,0,$5,$6,CURRENT_TIMESTAMP,$7,'active',FALSE)
       RETURNING *`,
      [
        userId,
        plan.id,
        usernameHotspot,
        passwordHotspot,
        plan.data_limit_gb,
        plan.speed_limit_mbps,
        expiryDate,
      ]
    );

    const subscription = subscriptionResult.rows[0];

    const reference = `INT-${Date.now()}-${userId}`;

    await client.query(
      `INSERT INTO internet_transactions (
         user_id,
         subscription_id,
         plan_id,
         amount,
         currency,
         payment_method,
         status,
         reference,
         description
       )
       VALUES ($1,$2,$3,$4,'USD','wallet','paid',$5,$6)`,
      [
        userId,
        subscription.id,
        plan.id,
        plan.price,
        reference,
        `Achat plan internet ${plan.name}`,
      ]
    );

    await client.query(
      `INSERT INTO transactions (
         user_id,
         type,
         amount,
         title,
         description,
         reference,
         created_at
       )
       VALUES ($1,'internet_plan',$2,$3,$4,$5,CURRENT_TIMESTAMP)`,
      [
        userId,
        plan.price,
        'Achat Plan Internet',
        `Plan ${plan.name}`,
        reference,
      ]
    );

    await client.query('COMMIT');

    try {
      await addHotspotUser({
        username: usernameHotspot,
        password: passwordHotspot,
        profile: plan.code,
      });
    } catch (mikroErr) {
      console.error('Erreur MikroTik:', mikroErr);
    }

    res.json({
      success: true,
      message: 'Plan internet acheté avec succès',
      subscription,
      balance: newBalance,
    });
  } catch (e) {
    await client.query('ROLLBACK');
    console.error('Erreur POST /buy-plan:', e);
    res.status(500).json({
      success: false,
      message: 'Erreur achat plan internet',
    });
  } finally {
    client.release();
  }
});

module.exports = router;