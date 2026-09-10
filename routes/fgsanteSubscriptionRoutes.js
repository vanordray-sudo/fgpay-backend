const express = require('express');
const jwt = require('jsonwebtoken');
const Stripe = require('stripe');
const pool = require('../db');

const router = express.Router();

const stripe = new Stripe(
  process.env.STRIPE_SECRET_KEY
);

// ======================================================
// AUTH FG SANTÉ
// ======================================================

function requireFgSanteAuth(req, res, next) {
  try {
    console.log(
  'FG SANTE ROUTE ACTIVE - NEW FILE'
);
    const authHeader = req.headers.authorization;

    if (
      !authHeader ||
      !authHeader.startsWith('Bearer ')
    ) {
      return res.status(401).json({
        success: false,
        message: 'Token manquant',
      });
    }

    const token = authHeader.substring(7);

    const decoded = jwt.verify(
      token,
      process.env.JWT_SECRET,
    );

    req.user = decoded;

    next();
  } catch (error) {
    console.error(
      'FG SANTE AUTH ERROR:',
      error.message,
    );

    return res.status(401).json({
      success: false,
      message: 'Token invalide ou expiré',
    });
  }
}

// ======================================================
// CRÉER UNE SESSION STRIPE
// ======================================================

router.post(
  '/pay-stripe',
  requireFgSanteAuth,
  async (req, res) => {

    console.log(
  '===== NOUVO ROUTE FG SANTE RESEVWA DEMANN LAN ====='
);
    try {
      console.log(
        'FG SANTE SUBSCRIPTION STRIPE CALLED',
      );

      console.log('USER:', req.user);
      console.log('BODY:', req.body);

      const { plan } = req.body;

      const plans = {
        monthly: {
          name: 'FG Santé Pro - Mensuel',
          amount: 3500,
        },

        quarterly: {
          name: 'FG Santé Pro - Trimestriel',
          amount: 10000,
        },

        yearly: {
          name: 'FG Santé Pro - Annuel',
          amount: 35000,
        },
      };

      const selectedPlan = plans[plan];

      if (!selectedPlan) {
        return res.status(400).json({
          success: false,
          message:
              'Plan d’abonnement invalide.',
        });
      }

      const frontendUrl =
          req.headers.origin ||
          process.env.FGSANTE_FRONTEND_URL ||
          'http://localhost:60788';

      const session =
          await stripe.checkout.sessions.create({
        mode: 'payment',

        payment_method_types: [
          'card',
        ],

        line_items: [
          {
            price_data: {
              currency: 'usd',

              product_data: {
                name: selectedPlan.name,
              },

              unit_amount:
                  selectedPlan.amount,
            },

            quantity: 1,
          },
        ],

       success_url:
  `${frontendUrl}/#/subscription-success?session_id={CHECKOUT_SESSION_ID}`,

cancel_url:
  `${frontendUrl}/#/subscription-cancel`,
        metadata: {
          source: 'fg_sante',

          payment_type:
              'fgsante_subscription',

          plan: plan,

          user_id: String(
            req.user?.id ??
                req.user?.user_id ??
                '',
          ),
        },
      });

      console.log(
        'FG SANTE STRIPE SESSION:',
        session.id,
      );

      return res.status(200).json({
        success: true,
        session_id: session.id,
        url: session.url,
      });
    } catch (error) {
      console.error(
        'FG SANTE STRIPE ERROR:',
        error,
      );

      return res.status(500).json({
        success: false,
        message:
            `Erreur Stripe: ${error.message}`,
      });
    }
  },
);
// ======================================================
// CONFIRMER ET ENREGISTRER L'ABONNEMENT
// ======================================================

router.post(
  '/confirm',
  requireFgSanteAuth,
  async (req, res) => {
    try {
      const { session_id } = req.body;

      if (!session_id) {
        return res.status(400).json({
          success: false,
          message: 'session_id manquant',
        });
      }

      const session =
          await stripe.checkout.sessions.retrieve(
        session_id,
      );

      if (session.payment_status !== 'paid') {
        return res.status(400).json({
          success: false,
          message:
              'Paiement Stripe non confirmé.',
        });
      }

      if (
        session.metadata?.source !== 'fg_sante' ||
        session.metadata?.payment_type !==
            'fgsante_subscription'
      ) {
        return res.status(400).json({
          success: false,
          message:
              'Session Stripe FG Santé invalide.',
        });
      }

      const plan = session.metadata?.plan;

      const userId =
          session.metadata?.user_id ||
          req.user?.id ||
          req.user?.user_id;

      if (!userId) {
        return res.status(400).json({
          success: false,
          message: 'Utilisateur introuvable.',
        });
      }

      const plans = {
        monthly: {
          amount: 35.00,
          interval: '1 month',
        },
        quarterly: {
          amount: 100.00,
          interval: '3 months',
        },
        yearly: {
          amount: 350.00,
          interval: '1 year',
        },
      };

      const selectedPlan = plans[plan];

      if (!selectedPlan) {
        return res.status(400).json({
          success: false,
          message:
              'Plan FG Santé invalide.',
        });
      }

      const existing =
          await pool.query(
        `
          SELECT id
          FROM fgsante_subscriptions
          WHERE stripe_session_id = $1
          LIMIT 1
        `,
        [session.id],
      );

      if (existing.rows.length > 0) {
        return res.status(200).json({
          success: true,
          message:
              'Abonnement déjà enregistré.',
        });
      }

      const result =
          await pool.query(
        `
          INSERT INTO fgsante_subscriptions (
            user_id,
            plan,
            status,
            amount,
            currency,
            started_at,
            expires_at,
            stripe_session_id,
            stripe_payment_intent_id,
            created_at,
            updated_at
          )
          VALUES (
            $1,
            $2,
            'active',
            $3,
            'USD',
            NOW(),
            NOW() + $4::interval,
            $5,
            $6,
            NOW(),
            NOW()
          )
          RETURNING *
        `,
        [
          userId,
          plan,
          selectedPlan.amount,
          selectedPlan.interval,
          session.id,
          session.payment_intent,
        ],
      );

      console.log(
        'FG SANTE SUBSCRIPTION ACTIVATED:',
        result.rows[0],
      );

      return res.status(200).json({
        success: true,
        subscription:
            result.rows[0],
      });
    } catch (error) {
      console.error(
        'FG SANTE CONFIRM SUBSCRIPTION ERROR:',
        error,
      );

      return res.status(500).json({
        success: false,
        message: error.message,
      });
    }
  },
);
// ======================================================
// LIRE MON ABONNEMENT FG SANTÉ
// ======================================================

router.get(
  '/me',
  requireFgSanteAuth,
  async (req, res) => {
    try {
      const userId =
          req.user?.id ??
          req.user?.user_id;

      if (!userId) {
        return res.status(400).json({
          success: false,
          message: 'Utilisateur introuvable.',
        });
      }

      const result =
          await pool.query(
        `
          SELECT
            id,
            user_id,
            plan,
            status,
            amount,
            currency,
            started_at,
            expires_at,
            stripe_session_id
          FROM fgsante_subscriptions
          WHERE user_id = $1
          ORDER BY created_at DESC
          LIMIT 1
        `,
        [userId],
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message:
              'Aucun abonnement FG Santé trouvé.',
        });
      }

      const subscription =
          result.rows[0];

      if (
        subscription.status === 'active' &&
        new Date(subscription.expires_at) <
            new Date()
      ) {
        await pool.query(
          `
            UPDATE fgsante_subscriptions
            SET
              status = 'expired',
              updated_at = NOW()
            WHERE id = $1
          `,
          [subscription.id],
        );

        subscription.status = 'expired';
      }

      return res.status(200).json({
        success: true,
        subscription,
      });
    } catch (error) {
      console.error(
        'FG SANTE GET SUBSCRIPTION ERROR:',
        error,
      );

      return res.status(500).json({
        success: false,
        message: error.message,
      });
    }
  },
);

module.exports = router;