# Easy Pay SSL

A complete Flutter payment integration application with SSLCOMMERZ payment gateway, featuring a Flutter frontend and Node.js Express backend.

## Features

- SSLCOMMERZ Payment Gateway Integration
- Secure Backend API with Node.js/Express
- Payment Validation & IPN Handling
- WebView for Mobile, New Tab for Web

## Payment Gateway

This app uses the SSLCOMMERZ Sandbox Validation API:  
[https://sandbox.sslcommerz.com/validator/api/validationserverAPI.php](https://sandbox.sslcommerz.com/validator/api/validationserverAPI.php)

## API Endpoints

- `/api/payment/initiate` – Initiate a new payment  
- `/api/payment/success` – Handle successful payment  
- `/api/payment/fail` – Handle failed payment  
- `/api/payment/cancel` – Handle canceled payment  
- `/api/payment/ipn` – Instant Payment Notification (IPN)  
- `/api/payment/status/:transactionId` – Retrieve payment status by transaction ID  
