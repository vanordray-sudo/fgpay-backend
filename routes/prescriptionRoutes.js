const express = require('express');
const router = express.Router();

const pool = require('../db');
const authMiddleware = require('../middleware/authMiddleware');



function generateVerificationCode(prefix = 'FG') {
  return `${prefix}-${Date.now()}-${Math.floor(Math.random() * 999999)}`;
}

// CREATE PRESCRIPTION
router.post('/create', authMiddleware, async (req, res) => {
  try {

    const doctor_id = req.userId;

   const {
  appointment_id,
  patient_id,
  patient_name,
  medication,
  medications,
  dosage,
  duration,
  instructions,
  notes,
  doctor_name,
  clinic_name,
  items,
} = req.body;


    const finalMedication = medication || medications;
    const verificationCode = generateVerificationCode('FGR');

    let finalPatientName = patient_name;

if (!finalPatientName && patient_id) {
  const patientResult = await pool.query(
    `SELECT name FROM users WHERE id = $1`,
    [patient_id]
  );

  finalPatientName = patientResult.rows[0]?.name || '';
}

    const result = await pool.query(
      `
      INSERT INTO prescriptions (
        appointment_id,
        doctor_id,
        patient_id,
        patient_name,
        medication,
        dosage,
        duration,
        instructions,
        doctor_name,
        clinic_name,
        notes,
        verification_code
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
      RETURNING *
      `,
     [
  appointment_id,
  doctor_id,
  patient_id,
  finalPatientName,
  finalMedication,
  dosage,
  duration,
  instructions,
  doctor_name,
  clinic_name,
  notes,
  verificationCode,
]
    );

    const prescription = result.rows[0];

if (items && items.length > 0) {
  for (const item of items) {
    await pool.query(
      `
      INSERT INTO prescription_items (
        prescription_id,
        medication,
        dosage,
        duration,
        instructions
      )
      VALUES ($1,$2,$3,$4,$5)
      `,
      [
        prescription.id,
        item.medication,
        item.dosage,
        item.duration,
        item.instructions,
      ]
    );
  }
}

prescription.items = items || [];

    await pool.query(
      `
      INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        is_read,
        created_at
      )
      VALUES ($1,$2,$3,$4,false,NOW())
      `,
      [
        patient_id,
        'Nouvelle prescription disponible',
        `Dr ${doctor_name} a ajouté une nouvelle prescription.

Médicament : ${finalMedication}
Durée : ${duration}`,
        'prescription',
      ]
    );

   const fullPrescription = {
  ...prescription,
  items: items || [],
};

res.json({
  success: true,
  prescription: fullPrescription,
});

  } catch (error) {
    console.log('PRESCRIPTION ERROR:', error);

    res.status(500).json({
      success: false,
      message: 'Erreur création prescription',
      error: error.toString(),
    });
  }
});


// GET PATIENT PRESCRIPTIONS
router.get('/patient', authMiddleware, async (req, res) => {
  try {
    const patient_id = 4;

    const result = await pool.query(
      `
     SELECT
  p.*,
  patient.name AS patient_name,
  doctor.name AS doctor_name
FROM prescriptions p
LEFT JOIN users patient
  ON p.patient_id = patient.id
LEFT JOIN users doctor
  ON p.doctor_id = doctor.id
WHERE p.patient_id = $1
ORDER BY p.created_at DESC
      `,
      [patient_id]
    );

    res.json({
      success: true,
      prescriptions: result.rows,
    });

  } catch (error) {
    console.log('GET PATIENT PRESCRIPTIONS ERROR:', error);

    res.status(500).json({
      success: false,
      message: 'Erreur récupération prescriptions patient',
    });
  }
});

router.post('/', authMiddleware, async (req, res) => {
  try {
    const {
      patient_id,
      appointment_id,
      medication,
      dosage,
      duration,
      notes,
      doctor_name,
      clinic_name,
      prescription_date
    } = req.body;

    const result = await pool.query(
      `
      INSERT INTO prescriptions (
        patient_id,
        doctor_id,
        appointment_id,
        medication,
        dosage,
        duration,
        notes,
        doctor_name,
        clinic_name,
        prescription_date
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
      RETURNING *
      `,
      [
        patient_id,
        req.userId,
        appointment_id,
        medication,
        dosage,
        duration,
        notes,
        doctor_name,
        clinic_name,
        prescription_date
      ]
    );

    res.json({
      success: true,
      prescription: result.rows[0]
    });

  } catch (error) {
    console.error('CREATE PRESCRIPTION ERROR:', error);

    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

router.get('/doctor', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT
        p.*,
        COALESCE(p.patient_name, u.name) AS patient_name
      FROM prescriptions p
      LEFT JOIN users u
        ON u.id = p.patient_id
      WHERE p.doctor_id = $1
      ORDER BY p.id DESC
      `,
      [req.userId]
    );

    res.json({
      success: true,
      prescriptions: result.rows,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.toString(),
    });
  }
});

router.get('/my-prescriptions/:patientId', authMiddleware, async (req, res) => {
  try {
    const patientId = req.params.patientId;

    const result = await pool.query(`
      SELECT
        p.*,
        COALESCE(p.doctor_name, d.name, d.email) AS doctor_name,
        COALESCE(u.name, p.patient_name) AS patient_name
      FROM prescriptions p
      LEFT JOIN users u ON p.patient_id = u.id
      LEFT JOIN users d ON p.doctor_id = d.id
      WHERE p.patient_id = $1
      ORDER BY p.id DESC
    `, [patientId]);

    res.json({
      success: true,
      prescriptions: result.rows,
    });
  } catch (error) {
    console.log('GET MY PRESCRIPTIONS ERROR:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur récupération prescriptions',
    });
  }
});

module.exports = router;