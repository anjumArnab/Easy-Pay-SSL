const express = require('express');
const cors = require('cors');
const axios = require('axios');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// SSLCOMMERZ Configuration
const STORE_ID = process.env.SSLCOMMERZ_STORE_ID;
const STORE_PASSWORD = process.env.SSLCOMMERZ_STORE_PASSWORD;
const IS_LIVE = process.env.SSLCOMMERZ_IS_LIVE === 'true';

// SSLCOMMERZ API URLs
const SSLCOMMERZ_API_URL = IS_LIVE 
  ? 'https://securepay.sslcommerz.com'
  : 'https://sandbox.sslcommerz.com';

const VALIDATION_API_URL = IS_LIVE
  ? 'https://securepay.sslcommerz.com/validator/api/validationserverAPI.php'
  : 'https://sandbox.sslcommerz.com/validator/api/validationserverAPI.php';

// Backend callback URLs
const SUCCESS_URL = `${process.env.BACKEND_URL}/api/payment/success`;
const FAIL_URL = `${process.env.BACKEND_URL}/api/payment/fail`;
const CANCEL_URL = `${process.env.BACKEND_URL}/api/payment/cancel`;
const IPN_URL = `${process.env.BACKEND_URL}/api/payment/ipn`;

// In-memory storage for transactions (use database in production)
const transactions = new Map();

// Health check endpoint
app.get('/', (req, res) => {
  res.json({ 
    status: 'success', 
    message: 'Easy Pay SSL Backend is running',
    mode: IS_LIVE ? 'LIVE' : 'SANDBOX'
  });
});

// Initiate Payment
app.post('/api/payment/initiate', async (req, res) => {
  try {
    const { amount, customerName, customerEmail, customerPhone, productName } = req.body;

    // Validation
    if (!amount || !customerName || !customerEmail || !customerPhone) {
      return res.status(400).json({
        status: 'error',
        message: 'Missing required fields'
      });
    }

    // Generate unique transaction ID
    const transactionId = `TXN${Date.now()}${Math.floor(Math.random() * 1000)}`;

    // Prepare SSLCOMMERZ payment data
    const paymentData = {
      store_id: STORE_ID,
      store_passwd: STORE_PASSWORD,
      total_amount: parseFloat(amount),
      currency: 'BDT',
      tran_id: transactionId,
      success_url: SUCCESS_URL,
      fail_url: FAIL_URL,
      cancel_url: CANCEL_URL,
      ipn_url: IPN_URL,
      product_name: productName || 'Product',
      product_category: 'General',
      product_profile: 'general',
      cus_name: customerName,
      cus_email: customerEmail,
      cus_add1: 'Dhaka',
      cus_city: 'Dhaka',
      cus_state: 'Dhaka',
      cus_postcode: '1000',
      cus_country: 'Bangladesh',
      cus_phone: customerPhone,
      shipping_method: 'NO',
      num_of_item: 1,
      product_amount: parseFloat(amount),
      vat: 0,
      discount_amount: 0,
      convenience_fee: 0
    };

    // Store transaction details
    transactions.set(transactionId, {
      ...paymentData,
      status: 'pending',
      createdAt: new Date().toISOString()
    });

    // Call SSLCOMMERZ API
    const response = await axios.post(
      `${SSLCOMMERZ_API_URL}/gwprocess/v4/api.php`,
      paymentData,
      {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      }
    );

    if (response.data.status === 'SUCCESS') {
      res.json({
        status: 'success',
        gatewayUrl: response.data.GatewayPageURL,
        transactionId: transactionId,
        sessionKey: response.data.sessionkey
      });
    } else {
      res.status(400).json({
        status: 'error',
        message: 'Failed to create payment session',
        details: response.data
      });
    }
  } catch (error) {
    console.error('Payment initiation error:', error.message);
    res.status(500).json({
      status: 'error',
      message: 'Internal server error',
      details: error.message
    });
  }
});

// Success Callback
app.post('/api/payment/success', async (req, res) => {
  try {
    const { tran_id, val_id, amount, card_type, store_amount, card_issuer, bank_tran_id } = req.body;

    console.log('Success callback received:', { tran_id, val_id, amount });

    // Validate payment with SSLCOMMERZ
    const validationResponse = await axios.get(VALIDATION_API_URL, {
      params: {
        val_id: val_id,
        store_id: STORE_ID,
        store_passwd: STORE_PASSWORD,
        format: 'json'
      }
    });

    const validationData = validationResponse.data;

    if (validationData.status === 'VALID' || validationData.status === 'VALIDATED') {
      // Update transaction status
      const transaction = transactions.get(tran_id);
      if (transaction) {
        transaction.status = 'success';
        transaction.validationId = val_id;
        transaction.bankTransactionId = bank_tran_id;
        transaction.cardType = card_type;
        transaction.completedAt = new Date().toISOString();
        transactions.set(tran_id, transaction);
      }

      // Redirect to Flutter app with success status
      res.redirect(`${process.env.FLUTTER_APP_URL || 'http://localhost:8080'}?status=success&tran_id=${tran_id}&amount=${amount}`);
    } else {
      res.redirect(`${process.env.FLUTTER_APP_URL || 'http://localhost:8080'}?status=failed&tran_id=${tran_id}&reason=validation_failed`);
    }
  } catch (error) {
    console.error('Success callback error:', error.message);
    res.redirect(`${process.env.FLUTTER_APP_URL || 'http://localhost:8080'}?status=error&reason=${encodeURIComponent(error.message)}`);
  }
});

// Failure Callback
app.post('/api/payment/fail', (req, res) => {
  try {
    const { tran_id, error } = req.body;

    console.log('Failure callback received:', { tran_id, error });

    // Update transaction status
    const transaction = transactions.get(tran_id);
    if (transaction) {
      transaction.status = 'failed';
      transaction.error = error;
      transaction.completedAt = new Date().toISOString();
      transactions.set(tran_id, transaction);
    }

    res.redirect(`${process.env.FLUTTER_APP_URL || 'http://localhost:8080'}?status=failed&tran_id=${tran_id}&reason=${encodeURIComponent(error || 'payment_failed')}`);
  } catch (error) {
    console.error('Failure callback error:', error.message);
    res.redirect(`${process.env.FLUTTER_APP_URL || 'http://localhost:8080'}?status=error`);
  }
});

// Cancel Callback
app.post('/api/payment/cancel', (req, res) => {
  try {
    const { tran_id } = req.body;

    console.log('Cancel callback received:', { tran_id });

    // Update transaction status
    const transaction = transactions.get(tran_id);
    if (transaction) {
      transaction.status = 'cancelled';
      transaction.completedAt = new Date().toISOString();
      transactions.set(tran_id, transaction);
    }

    res.redirect(`${process.env.FLUTTER_APP_URL || 'http://localhost:8080'}?status=cancelled&tran_id=${tran_id}`);
  } catch (error) {
    console.error('Cancel callback error:', error.message);
    res.redirect(`${process.env.FLUTTER_APP_URL || 'http://localhost:8080'}?status=error`);
  }
});

// IPN (Instant Payment Notification) Endpoint
app.post('/api/payment/ipn', async (req, res) => {
  try {
    const { tran_id, val_id, status, amount } = req.body;

    console.log('IPN received:', { tran_id, val_id, status, amount });

    // Validate payment
    const validationResponse = await axios.get(VALIDATION_API_URL, {
      params: {
        val_id: val_id,
        store_id: STORE_ID,
        store_passwd: STORE_PASSWORD,
        format: 'json'
      }
    });

    const validationData = validationResponse.data;

    if (validationData.status === 'VALID' || validationData.status === 'VALIDATED') {
      const transaction = transactions.get(tran_id);
      if (transaction) {
        transaction.status = 'success';
        transaction.ipnReceived = true;
        transaction.ipnReceivedAt = new Date().toISOString();
        transactions.set(tran_id, transaction);
      }

      res.status(200).send('IPN processed successfully');
    } else {
      res.status(400).send('Invalid payment');
    }
  } catch (error) {
    console.error('IPN error:', error.message);
    res.status(500).send('IPN processing error');
  }
});

// Get transaction status
app.get('/api/payment/status/:transactionId', (req, res) => {
  try {
    const { transactionId } = req.params;
    const transaction = transactions.get(transactionId);

    if (transaction) {
      res.json({
        status: 'success',
        transaction: {
          transactionId: transactionId,
          amount: transaction.total_amount,
          status: transaction.status,
          customerName: transaction.cus_name,
          customerEmail: transaction.cus_email,
          createdAt: transaction.createdAt,
          completedAt: transaction.completedAt
        }
      });
    } else {
      res.status(404).json({
        status: 'error',
        message: 'Transaction not found'
      });
    }
  } catch (error) {
    console.error('Status check error:', error.message);
    res.status(500).json({
      status: 'error',
      message: 'Internal server error'
    });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`Easy Pay SSL Backend running on port ${PORT}`);
  console.log(`Mode: ${IS_LIVE ? 'LIVE' : 'SANDBOX'}`);
  console.log(`Backend URL: ${process.env.BACKEND_URL}`);
});