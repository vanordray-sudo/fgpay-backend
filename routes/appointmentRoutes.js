const express = require('express');
const router = express.Router();

const pool = require('../db');
const authMiddleware = require('../middleware/authMiddleware');

// CREATE APPOINTMENT
router.post(
  '/',
  authMiddleware,
  async (req, res) => {
    try {
let {
  patient_id,
  doctor_id,
  referral_id,
  date,
  time,
  reason,
  patient_phone,
  doctor_name,
} = req.body;

 const appointment_date = date;
 const appointment_time = time;
      

console.log('REQ.BODY:', req.body);
console.log('REQ.USERID:', req.userId);

      // Chèche patient nan referral la
      if (referral_id) {

        const referralResult = await pool.query(
          'SELECT patient_id FROM referrals WHERE id = $1',
          [referral_id]
        );

        if (referralResult.rows.length === 0) {
          return res.status(404).json({
            success: false,
            message: 'Référence introuvable',
          });
        }

        patient_id =
            referralResult.rows[0].patient_id;
      }
const patientResult = await pool.query(
  `SELECT id FROM users WHERE phone = $1 LIMIT 1`,
  [patient_phone]
);

const doctorResult = await pool.query(
  `
  SELECT id FROM users
  WHERE health_role = 'doctor'
    AND (
      LOWER(name) LIKE LOWER($1)
      OR LOWER(full_name) LIKE LOWER($1)
    )
  LIMIT 1
  `,
  [`%${doctor_name}%`]
);

  if (!patient_id && patient_phone) {
  const patientResult = await pool.query(
    `SELECT id FROM users WHERE phone = $1 LIMIT 1`,
    [patient_phone]
  );
  patient_id = patientResult.rows[0]?.id || null;
}

if (!doctor_id && doctor_name) {
  const doctorResult = await pool.query(
    `
    SELECT id FROM users
    WHERE health_role = 'doctor'
      AND (
        LOWER(name) LIKE LOWER($1)
        OR LOWER(full_name) LIKE LOWER($1)
      )
    LIMIT 1
    `,
    [`%${doctor_name}%`]
  );
  doctor_id = doctorResult.rows[0]?.id || null;
}

if (!patient_id || !doctor_id) {
  return res.status(400).json({
    success: false,
    message: 'patient_id ou doctor_id manquant',
    patient_id,
    doctor_id,
  });
}
     console.log('CREATE APPOINTMENT FINAL:', {
  patient_id,
  doctor_id,
  referral_id,
  appointment_date,
  appointment_time,
  reason,
});

      const result = await pool.query(
        `
        INSERT INTO appointments (
          patient_id,
          doctor_id,
          referral_id,
          appointment_date,
          appointment_time,
          reason
        )
        VALUES ($1,$2,$3,$4,$5,$6)
        RETURNING *
        `,
        [
          patient_id,
          doctor_id,
          referral_id || null,
          appointment_date,
          appointment_time,
          reason
        ]
      );

// NOTIFY ADMINS - NEW APPOINTMENT REQUEST
await pool.query(
  `
  INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    is_read
  )
  SELECT
    id,
    $1,
    $2,
    $3,
    false
  FROM users
  WHERE health_role = 'admin'
  `,
  [
    'Nouvelle demande de rendez-vous',
    `Un patient vient de demander un rendez-vous avec le médecin ID ${doctor_id}.`,
    'appointment'
  ]
);

      res.json({
        success: true,
        message: 'Rendez-vous créé',
        appointment: result.rows[0],
      });

    } catch (err) {

      console.log('FULL ERROR:');
      console.log(err);

      res.status(500).json({
        success: false,
        message: 'Erreur création rendez-vous',
        error: err.toString(),
      });

    }
  }
);

router.get('/patients', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT id, full_name, name, phone
      FROM users
      WHERE health_role = 'patient'
      ORDER BY id DESC
    `);

    res.json({
      success: true,
      patients: result.rows,
    });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

router.get('/doctors', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT id, full_name, name, phone
      FROM users
      WHERE health_role = 'doctor'
        AND is_verified_professional = true
      ORDER BY id DESC
    `);
console.log('DOCTOR USER ID =', req.userId);
console.log('DOCTOR APPOINTMENTS FOUND =', result.rows);
    res.json({
      success: true,
      doctors: result.rows,
    });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

router.get('/appointments/admin', authMiddleware, async (req, res) => {
  try {

    const result = await pool.query(`
      SELECT
        id,
        patient_id,
        doctor_id,
        appointment_date,
        appointment_time,
        status
      FROM appointments
      ORDER BY id DESC
    `);

    res.json({
      success: true,
      appointments: result.rows,
    });

  } catch (err) {

    console.log(err);

    res.status(500).json({
      success: false,
      message: 'Erreur chargement rendez-vous admin',
    });
  }
});

// GET PATIENT APPOINTMENTS
router.get('/patient', authMiddleware, async (req, res) => {
  try {
    const patient_id = req.userId;

    const result = await pool.query(
      `
      SELECT
        a.id AS appointment_id,
        a.patient_id,
        a.doctor_id,
        a.appointment_date,
        a.appointment_time,
        a.reason,
        a.status AS appointment_status,
        d.name AS doctor_name,
        d.clinic_name
      FROM appointments a
      LEFT JOIN users d ON a.doctor_id = d.id
      WHERE a.patient_id = $1
      ORDER BY a.appointment_date DESC, a.appointment_time DESC
      `,
      [patient_id]
    );

    res.json({
      success: true,
      appointments: result.rows,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: 'Erreur récupération rendez-vous patient',
      error: err.toString(),
    });
  }
});

router.get('/doctors-list', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT id, full_name, name, phone
      FROM users
      WHERE health_role = 'doctor'
      ORDER BY id DESC
    `);
console.log('DOCTOR USER ID =', req.userId);
console.log('DOCTOR APPOINTMENTS FOUND =', result.rows);
    res.json({ success: true, doctors: result.rows });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// GET DOCTOR APPOINTMENTS
router.get('/doctor', authMiddleware, async (req, res) => {
  try {
    const doctor_id = req.userId;

    const result = await pool.query(
      `
     SELECT
a.id AS appointment_id,
a.patient_id,
a.doctor_id,
a.appointment_date,
a.appointment_time,
a.reason,
a.status,

patient.name AS patient_name,
doctor.name AS doctor_name

FROM appointments a
LEFT JOIN users patient
ON a.patient_id = patient.id

LEFT JOIN users doctor
ON a.doctor_id = doctor.id

WHERE a.doctor_id = $1
ORDER BY a.appointment_date DESC,
a.appointment_time DESC
      `,
      [doctor_id]
    );

console.log('APPOINTMENTS FOUND:', result.rows);
console.log('GET DOCTOR APPOINTMENTS USER:', req.userId);
console.log('DOCTOR ID:', req.userId);

    res.json({
      success: true,
      appointments: result.rows,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: 'Erreur récupération rendez-vous médecin',
      error: err.toString(),
    });
  }
});

router.get('/notifications/patient', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT *
      FROM notifications
      WHERE user_id = $1
      ORDER BY created_at DESC
      `,
      [req.userId]
    );

    res.json({
      success: true,
      notifications: result.rows,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.toString(),
    });
  }
});

// ADMIN - VOIR TOUS LES RENDEZ-VOUS PATIENTS
router.get('/admin/all', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        a.*,
        p.name AS patient_name,
        d.name AS doctor_name
      FROM appointments a
      LEFT JOIN users p ON p.id = a.patient_id
      LEFT JOIN users d ON d.id = a.doctor_id
      WHERE a.status IN ('pending', 'accepted')
      ORDER BY a.id DESC
    `);

    res.json({
      success: true,
      appointments: result.rows,
    });
  } catch (err) {
    console.error('ADMIN APPOINTMENTS ERROR:', err);
    res.status(500).json({
      success: false,
      message: 'Erreur chargement rendez-vous admin',
      error: err.toString(),
    });
  }
});

// UPDATE STATUS
router.put( '/:id/status',authMiddleware,async (req, res) => {
    try {
      const { status } = req.body;
      const { id } = req.params;

      const result = await pool.query(
        `
        UPDATE appointments
        SET status = $1
        WHERE id = $2
        RETURNING *
        `,
        [status, id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Rendez-vous introuvable',
        });
      }

      const appointment = result.rows[0];

      console.log('STATUS RECU:', status);
      console.log('APPOINTMENT UPDATED:', appointment);
      console.log('FULL APPOINTMENT:', appointment);
      console.log('APPOINTMENT UPDATED:', appointment);
      console.log('PATIENT ID NOTIF:', appointment.patient_id);

    console.log('ADMIN NOTIF BLOCK START');

const formattedDate = new Date(appointment.appointment_date)
  .toLocaleDateString('fr-FR');

const formattedTime = String(appointment.appointment_time || '').slice(0, 5);

const adminNotif = await pool.query(
  `
  INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    is_read
  )
  SELECT
    id,
    $1,
    $2,
    $3,
    false
  FROM users
  WHERE health_role = 'admin'
  RETURNING *
  `,
  [
    'Rendez-vous accepté',
    `Votre rendez-vous chez Dr ${appointment.doctor_name || 'le médecin'} est accepté.\n\nDate : ${formattedDate}\nHeure : ${formattedTime}`,
    'appointment'
  ]
);
console.log('ADMIN NOTIF CREATED:', adminNotif.rows[0]);
      res.json({
        success: true,
        appointment,
      });


    } catch (err) {
      console.error('UPDATE STATUS ERROR:', err);

      res.status(500).json({
        success: false,
        message: 'Erreur update status',
        error: err.toString(),
      });
    }
  }
);

router.post('/:id/accept', authMiddleware, async (req, res) => {
  try {

   const appointmentResult = await pool.query(
  `
  SELECT
    a.*,
    u.name AS doctor_name
  FROM appointments a
  LEFT JOIN users u
    ON u.id = a.doctor_id
  WHERE a.id = $1
  `,
  [req.params.id]
);

    if (appointmentResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Rendez-vous introuvable',
      });
    }

    const appointment = appointmentResult.rows[0];

    await pool.query(
      `
      UPDATE appointments
      SET status = 'accepted'
      WHERE id = $1
      `,
      [req.params.id]
    );

console.log('APPOINTMENT:', appointment);
console.log('PATIENT ID:', appointment.patient_id);

const rdvDate = new Date(appointment.appointment_date);

const formattedDate =
  `${String(rdvDate.getDate()).padStart(2, '0')}/` +
  `${String(rdvDate.getMonth() + 1).padStart(2, '0')}/` +
  `${rdvDate.getFullYear()}`;

const formattedTime =
  appointment.appointment_time.toString().substring(0, 5);

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
    appointment.patient_id,
    'Rendez-vous accepté',
    `Votre rendez-vous chez Dr ${appointment.doctor_name} est accepté.

Date : ${formattedDate}
Heure : ${formattedTime}`,
    'appointment',
  ]
);
    res.json({
      success: true,
      message: 'Rendez-vous accepté',
    });

  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.toString(),
    });
  }
});

router.get('/doctor/next', authMiddleware, async (req, res) => {
  try {
    const doctorId = req.userId;

    const result = await pool.query(
      `
      
  SELECT
  a.*,
  u.full_name AS patient_name,
  u.phone AS patient_phone,
  NULL AS patient_birth_date
FROM appointments a
JOIN users u ON u.id = a.patient_id
WHERE a.doctor_id = $1
AND a.status IN ('confirmed','pending','accepted')
AND a.appointment_date >= CURRENT_DATE
ORDER BY a.appointment_date ASC, a.appointment_time ASC
LIMIT 1
      `,
      [doctorId]
    );
console.log('NEXT APPOINTMENT:', result.rows[0]);
    return res.json({
      success: true,
      appointment: result.rows[0] || null,
    });

  } catch (e) {
    console.error('NEXT APPOINTMENT ERROR:', e);

    return res.status(500).json({
      success: false,
      message: 'Erreur prochain rendez-vous',
      error: e.message,
    });
  }
});

router.put(
  '/:id/complete',
  authMiddleware,
  async (req, res) => {

    const appointmentId = req.params.id;

    await pool.query(
      `
      UPDATE appointments
      SET status = 'completed'
      WHERE id = $1
      `,
      [appointmentId]
    );

    res.json({
      success: true,
    });
  }
);

router.put('/:id/accept', authMiddleware, async (req, res) => {
  const appointmentId = req.params.id;

  try {
    const appointmentResult = await pool.query(
      `
      UPDATE appointments
      SET status = 'accepted'
      WHERE id = $1
      RETURNING *
      `,
      [appointmentId]
    );

    if (appointmentResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Rendez-vous introuvable',
      });
    }

    const appointment = appointmentResult.rows[0];

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
      VALUES ($1, $2, $3, $4, false, NOW())
      `,
      [
        appointment.patient_id,
        'Rendez-vous accepté',
        'Votre rendez-vous a été accepté par le médecin.',
        'appointment',
      ]
    );

    res.json({
      success: true,
      message: 'Rendez-vous accepté et notification envoyée au patient',
      appointment,
    });
  } catch (err) {
    console.log('ERROR ACCEPT APPOINTMENT:', err);

    res.status(500).json({
      success: false,
      message: 'Erreur acceptation rendez-vous',
      error: err.toString(),
    });
  }
});

router.get('/patient', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT *
      FROM appointments
      WHERE patient_id = $1
      ORDER BY appointment_date DESC, appointment_time DESC
      `,
      [req.userId]
    );
console.log('REQ USER ID:', req.userId);
    res.json({
      success: true,
      appointments: result.rows,
    });
  } catch (err) {
    console.log('ERROR PATIENT APPOINTMENTS:', err);
    res.status(500).json({
      success: false,
      error: err.toString(),
    });
  }
});

router.get('/doctor', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT *
      FROM prescriptions
      WHERE doctor_id = $1
      ORDER BY id DESC
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

router.get('/doctor', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT 
        a.*,
        u.name AS patient_name
      FROM appointments a
      LEFT JOIN users u 
        ON u.id = a.patient_id
      WHERE a.doctor_id = $1
      ORDER BY a.appointment_date DESC
      `,
      [req.userId]
    );

    res.json({
      success: true,
      appointments: result.rows,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

module.exports = router;