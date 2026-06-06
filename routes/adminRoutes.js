const express = require('express');
const router = express.Router();
const pool = require('../db');

router.get('/manual-payments', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT *
      FROM transactions
      WHERE status = 'pending'
      ORDER BY id DESC
    `);

    res.json({
      success: true,
      payments: result.rows,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

router.post('/manual-payments/:id/validate', async (req, res) => {
  const paymentId = req.params.id;

  try {
    const paymentResult = await pool.query(
      `SELECT * FROM transactions WHERE id = $1 AND status = 'pending'`,
      [paymentId]
    );

    if (paymentResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Paiement introuvable ou déjà traité',
      });
    }

    const payment = paymentResult.rows[0];

    await pool.query(
      `UPDATE users SET balance = balance + $1 WHERE id = $2`,
      [payment.amount, payment.receiver_id || payment.user_id]
    );

    await pool.query(
      `UPDATE transactions SET status = 'approved' WHERE id = $1`,
      [paymentId]
    );

    res.json({
      success: true,
      message: 'Paiement validé et wallet crédité',
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      message: 'Erreur validation paiement',
    });
  }
});

router.post('/manual-payments/:id/reject', async (req, res) => {
  const paymentId = req.params.id;

  try {
    await pool.query(
      `UPDATE transactions SET status = 'rejected' WHERE id = $1 AND status = 'pending'`,
      [paymentId]
    );

    res.json({
      success: true,
      message: 'Paiement rejeté',
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      message: 'Erreur rejet paiement',
    });
  }
});

router.put('/professionals/:id/approve', async (req,res)=>{
   try{

      await pool.query(
      `
      UPDATE professional_profiles
      SET status='approved'
      WHERE id=$1
      `,
      [req.params.id]
      );

      res.json({
         success:true
      });

   } catch(e){

      console.log(e);

      res.status(500).json({
         success:false
      });
   }
});


router.put('/professionals/:id/reject', async (req,res)=>{
   try{

      await pool.query(
      `
      UPDATE professional_profiles
      SET status='rejected'
      WHERE id=$1
      `,
      [req.params.id]
      );

      res.json({
         success:true
      });

   } catch(e){

      console.log(e);

      res.status(500).json({
         success:false
      });
   }
});

router.get('/professionals/pending', async (req,res)=>{
   try{

      const result = await pool.query(`
      SELECT *
      FROM professional_profiles
      WHERE status='pending'
      ORDER BY created_at DESC
      `);

      res.json({
         success:true,
         professionals: result.rows
      });

   } catch(e){

      console.log(e);

      res.status(500).json({
         success:false
      });
   }
});
module.exports = router;
