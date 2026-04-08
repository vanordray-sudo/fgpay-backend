const express = require('express');
const Stripe = require('stripe');

const router = express.Router();
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

// CREATE CHECKOUT SESSION
router.post('/create-checkout-session', async (req, res) => {
  try {
    const { serviceName, amount, currency } = req.body;

    if (!serviceName || !amount) {
      return res.status(400).json({
        success: false,
        message: 'serviceName et amount sont requis',
      });
    }

    const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:52096';
    const finalCurrency = (currency || 'eur').toLowerCase();

    const session = await stripe.checkout.sessions.create({
      mode: 'payment',
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: finalCurrency,
            product_data: {
              name: serviceName,
            },
            unit_amount: Math.round(Number(amount) * 100),
          },
          quantity: 1,
        },
      ],
      success_url: `${frontendUrl}/#/payment-success`,
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

module.exports = router;