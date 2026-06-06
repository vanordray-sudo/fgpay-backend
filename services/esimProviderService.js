const axios = require('axios');
const QRCode = require('qrcode');

const MODE = process.env.ESIM_PROVIDER_MODE || 'mock';
const BASE_URL = process.env.ESIM_PROVIDER_BASE_URL || '';
const API_KEY = process.env.ESIM_PROVIDER_API_KEY || '';
const PROVIDER_NAME = process.env.ESIM_PROVIDER_NAME || 'mock_provider';

async function generateQrCodeDataUrl(text) {
  return QRCode.toDataURL(text);
}

function buildActivationString({ smdpAddress, matchingId }) {
  return `LPA:1$${smdpAddress}$${matchingId}`;
}

async function createMockEsim(order) {
  const activationCode = `ACT-${Date.now()}`;
  const manualCode = `MANUAL-${Date.now()}`;
  const smdpAddress = 'fgconnect.com';
  const matchingId = `FG-${Date.now()}`;
  const activationString = buildActivationString({
    smdpAddress,
    matchingId,
  });
  const qrCodeUrl = await generateQrCodeDataUrl(activationString);

  return {
    providerName: 'mock_provider',
    providerOrderId: `MOCK-ORDER-${Date.now()}`,
    iccid: '8988307000000000000',
    matchingId,
    smdpAddress,
    activationCode,
    manualCode,
    qrCodeUrl,
    status: 'released',
    raw: {
      mode: 'mock',
      order,
    },
  };
}

async function createRealEsim(order) {
  if (!BASE_URL || !API_KEY) {
    throw new Error('Provider eSIM non configuré dans .env');
  }

  // item/name dwe koresponn ak bundle name provider la
  const bundleName = order.planCode || order.planName;
  if (!bundleName) {
    throw new Error('Plan eSIM invalide: bundle name manquant');
  }

  const headers = {
    'Content-Type': 'application/json',
    'X-API-Key': API_KEY,
  };

  // 1) Kreye order ak assign=true pou provider a asiyen bundle a sou yon nouvo eSIM
  const createPayload = {
    type: 'bundle',
    assign: true,
    description: `FGCONNECT-${order.userId}-${Date.now()}`,
    items: [
      {
        name: bundleName,
        quantity: 1,
      },
    ],
  };

  const createResponse = await axios.post(
    `${BASE_URL}/orders`,
    createPayload,
    { headers, timeout: 30000 }
  );

  const createData = createResponse.data || {};

  const orderReference =
    createData?.orderReference ||
    createData?.reference ||
    createData?.id ||
    createData?.order?.orderReference ||
    '';

  if (!orderReference) {
    throw new Error('orderReference manquant dans la réponse provider');
  }

  // 2) Chèche detay order la pou nou pran iccid + matchingId + smdpAddress
  const detailResponse = await axios.get(
    `${BASE_URL}/orders/${encodeURIComponent(orderReference)}`,
    { headers, timeout: 30000 }
  );

  const detailData = detailResponse.data || {};
  const esims =
    detailData?.order?.[0]?.esims ||
    detailData?.order?.esims ||
    detailData?.esims ||
    [];

  const esim = Array.isArray(esims) && esims.length > 0 ? esims[0] : null;

  const iccid = esim?.iccid || '';
  const matchingId = esim?.matchingId || '';
  const smdpAddress = esim?.smdpAddress || '';

  if (!iccid || !matchingId || !smdpAddress) {
    throw new Error(
      'ICCID / matchingId / smdpAddress manquant dans la réponse provider'
    );
  }

  const activationString = buildActivationString({
    smdpAddress,
    matchingId,
  });

  const qrCodeUrl = await generateQrCodeDataUrl(activationString);

  return {
    providerName: PROVIDER_NAME,
    providerOrderId: orderReference,
    iccid,
    matchingId,
    smdpAddress,
    activationCode: matchingId,
    manualCode: matchingId,
    qrCodeUrl,
    status: 'released',
    raw: detailData,
  };
}

async function createEsim(order) {
  if (MODE === 'real') {
    return createRealEsim(order);
  }
  return createMockEsim(order);
}

module.exports = {
  createEsim,
};



// services/esimProviderService.js

async function buyEsimFromProvider({ providerPlanId, planId, userId }) {
  const mode = process.env.ESIM_PROVIDER_MODE || 'mock';
  const apiKey = process.env.ESIMGO_API_KEY;
  const baseUrl = process.env.ESIMGO_BASE_URL || 'https://api.esim-go.com/v2.4';

  // ✅ MODE MOCK SAFE — pou app la pa bloke
  if (mode !== 'real') {
    console.log('⚠️ ESIM MOCK MODE ACTIVE');

    return {
      provider: 'mock',
      iccid: `TEST-${Date.now()}-${userId}`,
      activationCode: `TEST-ACT-${planId}-${Date.now()}`,
      qrCode: `LPA:1$test.fgconnect.local$${planId}-${userId}-${Date.now()}`,
      providerResponse: null,
    };
  }

  // ✅ MODE REAL
  if (!apiKey) {
    throw new Error('ESIMGO_API_KEY manquant');
  }

  if (!providerPlanId) {
    throw new Error('provider_plan_id manquant');
  }

  const response = await axios.post(
    `${baseUrl}/orders`,
    {
      type: 'transaction',
      assign: true,
      order: [
        {
          type: 'bundle',
          quantity: 1,
          item: providerPlanId,
        },
      ],
    },
    {
      headers: {
        'X-API-Key': apiKey,
        'Content-Type': 'application/json',
      },
      timeout: 30000,
    }
  );

  const order = response.data?.order?.[0] || {};
  const esim = order.esims?.[0] || {};

  const iccid = esim.iccid || order.iccids?.[0] || '';
  const matchingId = esim.matchingId || '';
  const smdpAddress = esim.smdpAddress || '';

  return {
    provider: 'esimgo',
    iccid,
    activationCode: matchingId,
    smdpAddress,
    qrCode: smdpAddress && matchingId
      ? `LPA:1$${smdpAddress}$${matchingId}`
      : '',
    providerResponse: response.data,
  };
}

module.exports = {
  buyEsimFromProvider,
};