const express = require('express');
const axios = require('axios');
const pool = require('../db');

const router = express.Router();

const PAYPAL_BASE_URL =
  process.env.PAYPAL_MODE === 'live'
    ? 'https://api-m.paypal.com'
    : 'https://api-m.sandbox.paypal.com';

async function getPayPalAccessToken() {
  const clientId = process.env.PAYPAL_CLIENT_ID;
  const secret = process.env.PAYPAL_SECRET;

  const auth = Buffer.from(`${clientId}:${secret}`).toString('base64');

  const response = await axios.post(
    `${PAYPAL_BASE_URL}/v1/oauth2/token`,
    'grant_type=client_credentials',
    {
      headers: {
        Authorization: `Basic ${auth}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    }
  );

  return response.data.access_token;
}


router.post('/create-order', async (req, res) => {
  try {
    const { amount, currency, userId, serviceName } = req.body || {};

    const parsedAmount = Number(amount);
    const parsedUserId = Number(userId);
    const finalCurrency = (currency || 'EUR').toUpperCase();

    if (!parsedAmount || parsedAmount <= 0 || !parsedUserId) {
      return res.status(400).json({
        success: false,
        message: 'amount et userId valides sont requis',
      });
    }

    const userCheck = await pool.query(
      'SELECT id FROM users WHERE id = $1 LIMIT 1',
      [parsedUserId]
    );

    if (userCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur introuvable avant création order PayPal',
      });
    }

    const accessToken = await getPayPalAccessToken();

    const response = await axios.post(
      `${PAYPAL_BASE_URL}/v2/checkout/orders`,
      {
        intent: 'CAPTURE',
        purchase_units: [
          {
            reference_id: String(parsedUserId),
            description: serviceName || 'FGPay Recharge',
            amount: {
              currency_code: finalCurrency,
              value: parsedAmount.toFixed(2),
            },
            custom_id: JSON.stringify({
              userId: parsedUserId,
              amount: parsedAmount,
              serviceName: serviceName || 'FGPay Recharge',
            }),
          },
        ],
        application_context: {
          brand_name: 'FGCONNECT',
          user_action: 'PAY_NOW',
          return_url: 'http://localhost:64505/#/paypal-success',
          cancel_url: 'http://localhost:64505/#/paypal-cancel',
        },
      },
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
      }
    );

    const approvalUrl = response.data.links?.find(
      (link) => link.rel === 'approve'
    )?.href;

    return res.json({
      success: true,
      orderId: response.data.id,
      approvalUrl,
      paypalOrder: response.data,
    });
  } catch (error) {
    console.error(
      'PAYPAL CREATE ORDER ERROR:',
      error.response?.data || error.message
    );

    return res.status(500).json({
      success: false,
      message: 'Erreur création order PayPal',
      error: error.response?.data || error.message,
    });
  }
});
module.exports = router;