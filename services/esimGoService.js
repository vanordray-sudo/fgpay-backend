const axios = require('axios');

const ESIMGO_BASE_URL = process.env.ESIMGO_BASE_URL || 'https://api.esim-go.com/v2.4';

const esimGoClient = axios.create({
  baseURL: ESIMGO_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
    'X-API-Key': process.env.ESIMGO_API_KEY,
  },
  timeout: 30000,
});

async function validateOrder({ bundleName, quantity = 1 }) {
  const payload = {
    type: 'validate',
    assign: true,
    Order: [
      {
        type: 'bundle',
        quantity,
        item: bundleName,
      },
    ],
  };

  const { data } = await esimGoClient.post('/orders', payload);
  return data;
}

async function processOrder({ bundleName, quantity = 1 }) {
  const payload = {
    type: 'transaction',
    assign: true,
    Order: [
      {
        type: 'bundle',
        quantity,
        item: bundleName,
      },
    ],
  };

  const { data } = await esimGoClient.post('/orders', payload);
  return data;
}

module.exports = {
  validateOrder,
  processOrder,
};