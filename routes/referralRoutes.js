const express = require('express');
const router = express.Router();
const pool = require('../db');
const authMiddleware = require('../middleware/authMiddleware');


// GET REFERRALS
router.get('/', authMiddleware, async (req, res) => {
  try {

    const result = await pool.query(`
      SELECT
       referrals.patient_id,
       patients.name AS patient_name,
       doctors.name AS doctor
        medical_specialties.name AS referred_specialty,
        referrals.reason,
        referrals.status,
        referrals.created_at

        r.patient_id,
        u.name AS patient_name,
        u.phone AS patient_phone,

      FROM referrals

      LEFT JOIN users patients
      ON referrals.patient_id = patients.id

      LEFT JOIN users doctors
      ON referrals.from_doctor_id = doctors.id

      LEFT JOIN medical_specialties
      ON referrals.to_specialty_id = medical_specialties.id

      ORDER BY referrals.created_at DESC
    `);

   res.json({
  success: true,
  referrals: result.rows.map((r) => ({
    id: r.id,
    patient_id: r.patient_id,
    patient_name: r.patient_name || r.patient,
    doctor_id: r.from_doctor_id,
    doctor_name: r.doctor,
    specialty: r.referred_specialty,
    reason: r.reason,
    status: r.status,
    created_at: r.created_at,
  })),
});

  } catch (error) {
    console.error(error);

    res.status(500).json({
      success: false,
      message: 'Erreur serveur'
    });
  }
});



module.exports = router;


/*
========================================
CREATE REFERRAL
========================================
*/

router.post(
  '/create',
  authMiddleware,
  async (req, res) => {

    try {

      const {
  patient_id,
  to_specialty_id,
  reason,
  priority
} = req.body;

      const from_doctor_id = req.userId;

     const result = await pool.query(
  `
  INSERT INTO referrals
  (
    patient_id,
    from_doctor_id,
    to_specialty_id,
    reason,
    priority
  )
  VALUES ($1, $2, $3, $4, $5)
  RETURNING *
  `,
  [
    patient_id,
    from_doctor_id,
    to_specialty_id,
    reason,
    priority
  ]
);
      res.json({
        success: true,
        referral: result.rows[0]
      });

    } catch (error) {

      console.error(error);

      res.status(500).json({
        success: false,
        message: 'Erreur création referral'
      });
    }
  }
);

router.post('/create', authMiddleware, async (req, res) => {
  try {
    const {
      patient_id,
      to_specialty_id,
      reason,
      priority
    } = req.body;

    const from_doctor_id = req.userId;

    const result = await pool.query(
      `
      INSERT INTO referrals
      (
        patient_id,
        from_doctor_id,
        to_specialty_id,
        reason,
        priority
      )
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
      `,
      [
        patient_id,
        from_doctor_id,
        to_specialty_id,
        reason,
        priority
      ]
    );

    res.json({
      success: true,
      referral: result.rows[0]
    });

  } catch (error) {
    console.error('Erreur création referral:', error);

    res.status(500).json({
      success: false,
      message: 'Erreur serveur'
    });
  }
});

router.get('/doctor', authMiddleware, async (req, res) => {

  try {

    const doctorId = req.userId;

    const result = await pool.query(`
      SELECT
        referrals.id,
        patients.name AS patient,
        medical_specialties.name AS specialty,
        referrals.reason,
        referrals.status,
        referrals.created_at
      FROM referrals
      LEFT JOIN users patients
        ON referrals.patient_id = patients.id
      LEFT JOIN medical_specialties
        ON referrals.to_specialty_id = medical_specialties.id
      WHERE referrals.from_doctor_id = $1
      ORDER BY referrals.created_at DESC
    `, [doctorId]);

    res.json({
      success: true,
      referrals: result.rows,
    });

  } catch (error) {

    console.error(error);

    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });

  }

});

/*
========================================
PATIENT REFERRALS
========================================
*/

router.get('/patient', authMiddleware, async (req, res) => {

  try {

    const patientId = req.userId;

    const result = await pool.query(`
      SELECT
        referrals.id,
        doctors.name AS doctor,
        medical_specialties.name AS specialty,
        referrals.reason,
        referrals.status,
        referrals.created_at
      FROM referrals
      LEFT JOIN users doctors
        ON referrals.from_doctor_id = doctors.id
      LEFT JOIN medical_specialties
        ON referrals.to_specialty_id = medical_specialties.id
      WHERE referrals.patient_id = $1
      ORDER BY referrals.created_at DESC
    `, [patientId]);

    res.json({
      success: true,
      referrals: result.rows,
    });

  } catch (error) {

    console.error(error);

    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });

  }

});



// =============================
// GET DOCTOR REFERRALS
// =============================
exports.getDoctorReferrals = async (req, res) => {
  try {
    const doctorId = req.userId;

    const result = await pool.query(`
      SELECT
        referrals.id,
        patients.name AS patient,
        medical_specialties.name AS specialty,
        referrals.reason,
        referrals.status,
        referrals.created_at
      FROM referrals
      LEFT JOIN users patients
        ON referrals.patient_id = patients.id
      LEFT JOIN medical_specialties
        ON referrals.to_specialty_id = medical_specialties.id
      WHERE referrals.from_doctor_id = $1
      ORDER BY referrals.created_at DESC
    `, [doctorId]);

    res.json({
      success: true,
      referrals: result.rows,
    });

  } catch (error) {
    console.error(error);

    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
};

router.put('/:id/status', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const result = await pool.query(
      `
      UPDATE referrals
      SET status = $1
      WHERE id = $2
      RETURNING *
      `,
      [status, id]
    );

    res.json({
      success: true,
      referral: result.rows[0],
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      success: false,
      message: 'Erreur update referral',
    });
  }
});

// =============================
// GET PATIENT REFERRALS
// =============================
exports.getPatientReferrals = async (req, res) => {
  try {
    const patientId = req.userId;

    const result = await pool.query(`
      SELECT
        referrals.id,
        doctors.name AS doctor,
        medical_specialties.name AS specialty,
        referrals.reason,
        referrals.status,
        referrals.created_at
      FROM referrals
      LEFT JOIN users doctors
        ON referrals.from_doctor_id = doctors.id
      LEFT JOIN medical_specialties
        ON referrals.to_specialty_id = medical_specialties.id
      WHERE referrals.patient_id = $1
      ORDER BY referrals.created_at DESC
    `, [patientId]);

    res.json({
      success: true,
      referrals: result.rows,
    });

  } catch (error) {
    console.error(error);

    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
};

/*
========================================
UPDATE REFERRAL STATUS
========================================
*/

router.put(
  '/status/:id',
  authMiddleware,
  async (req, res) => {

    try {

      const referralId = req.params.id;

      const {
        status
      } = req.body;

      const result = await pool.query(

        `
        UPDATE referrals

        SET status = $1

        WHERE id = $2

        RETURNING *
        `,
        [
          status,
          referralId
        ]
      );

      res.json({
        success: true,
        referral: result.rows[0]
      });

    } catch (error) {

      console.error(error);

      res.status(500).json({
        message: 'Erreur update referral'
      });
    }
  }
);

router.put('/:id/status', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!['accepted', 'rejected', 'pending'].includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Statut invalide',
      });
    }

    const result = await pool.query(
      `
      UPDATE referrals
      SET status = $1
      WHERE id = $2
      RETURNING *
      `,
      [status, id]
    );

    res.json({
      success: true,
      referral: result.rows[0],
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      success: false,
      message: 'Erreur update referral',
    });
  }
});

module.exports = router;