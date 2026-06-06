const express = require('express');
const router = express.Router();
const multer = require('multer');
const authMiddleware = require('../middleware/authMiddleware');
const pool = require('../db');

const upload = multer({
  dest: 'uploads/'
});

router.get('/pending', authMiddleware, async (req, res) => {
  try {



    console.log('CLICK PENDING OK');

    const pending = await pool.query(`
      SELECT
      id,
      name,
      specialty,
      phone,
      address,
      order_number,
      clinic,
      document,
      status,
      created_at
      FROM professional_profiles
      WHERE status='pending'
      ORDER BY id DESC
    `);

    console.log('PENDING FOUND:', pending.rows);

    return res.json({
      success: true,
      professionals: pending.rows
    });

  } catch (err) {

    console.log(err);

    return res.status(500).json({
      success: false,
      message: 'Erreur serveur'
    });
  }
});

router.post(
  '/create',
  authMiddleware,
  upload.single('document'),
  async (req, res) => {
    try {
      const userId = req.userId;

      const {
        name,
        specialty,
        phone,
        address,
        order_number,
        clinic
      } = req.body;

      const document =
          req.file ? req.file.filename : null;

      const result = await pool.query(
        `
        INSERT INTO professional_profiles
        (
          user_id,
          name,
          specialty,
          phone,
          address,
          order_number,
          clinic,
          document,
          status
        )
        VALUES
        (
          $1,$2,$3,$4,$5,$6,$7,$8,'pending'
        )
        RETURNING *
        `,
        [
          userId,
          name,
          specialty,
          phone,
          address,
          order_number,
          clinic,
          document
        ]
      );

      res.json({
        success: true,
        profile: result.rows[0]
      });

    } catch (e) {
      console.log(e);

      res.status(500).json({
        success:false,
        message:"Erreur serveur"
      });
    }
  }
);
router.put('/:id/approve', authMiddleware, async (req, res) => {
  await pool.query(
    `UPDATE professional_profiles
     SET status = 'approved'
     WHERE id = $1`,
    [req.params.id]
  );

  res.json({ success: true });
});

router.put('/:id/reject', authMiddleware, async (req, res) => {
  await pool.query(
    `UPDATE professional_profiles
     SET status = 'rejected'
     WHERE id = $1`,
    [req.params.id]
  );

  res.json({ success: true });
});
module.exports = router;