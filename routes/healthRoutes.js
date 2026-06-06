const multer = require('multer');
const path = require('path');

const express = require('express');
const router = express.Router();
const pool = require('../db');
const auth = require('../middleware/auth');
const authMiddleware = require('../middleware/auth');



const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/medical-results');
  },
  filename: (req, file, cb) => {
  cb(
    null,
    Date.now() + '-' + file.originalname
  );
},
});

const upload = multer({ storage });


router.get('/professionals/me/status', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT professional_status
      FROM users
      WHERE id = $1
      `,
      [req.userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        message: 'Utilisateur introuvable'
      });
    }

    return res.json({
      status: result.rows[0].professional_status || 'pending'
    });

  } catch (error) {
    console.error('Erreur statut professionnel:', error);

    return res.status(500).json({
      message: 'Erreur serveur'
    });
  }
});


router.post('/subscribe',authMiddleware,async (req, res) => {
    try {
      const userId = req.userId;
      const { planType } = req.body;

      let amount = 0;
      let months = 0;

      if (planType === 'monthly') {
        amount = 35;
        months = 1;
      }

      if (planType === 'quarterly') {
        amount = 100;
        months = 3;
      }

      if (planType === 'yearly') {
        amount = 350;
        months = 12;
      }

      const userResult = await pool.query(
        `
        SELECT *
        FROM users
        WHERE id = $1
        `,
        [userId]
      );

      const user = userResult.rows[0];

      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'Utilisateur introuvable'
        });
      }

      if (Number(user.balance) < amount) {
        return res.status(400).json({
          success: false,
          message: 'Solde insuffisant'
        });
      }

      const endDate = new Date();
      endDate.setMonth(endDate.getMonth() + months);

      await pool.query(
        `
        UPDATE users
        SET balance = balance - $1,
            subscription_status = 'active',
            subscription_end_date = $2
        WHERE id = $3
        `,
        [amount, endDate, userId]
      );

      await pool.query(
        `
        INSERT INTO professional_subscriptions
        (
          professional_id,
          plan_type,
          amount,
          payment_status,
          end_date
        )
        VALUES
        ($1,$2,$3,'paid',$4)
        `,
        [
          userId,
          planType,
          amount,
          endDate
        ]
      );

      res.json({
        success: true,
        message: 'Abonnement activé',
        endDate
      });

    } catch (err) {

      console.log(err);

      res.status(500).json({
        success: false,
        message: 'Erreur abonnement'
      });

    }
  }
);

// =============================
// GET MEDICAL RECORDS
// =============================
router.get('/records', auth, async (req, res) => {
  try {
    const result = await pool.query(
  `
  SELECT *
  FROM medical_records
  WHERE patient_id = $1
  ORDER BY created_at DESC
  `,
  [req.userId]
);

console.log("PATIENT RECORDS:", result.rows);

    res.json({
      success: true,
      records: result.rows,
    });

  } catch (err) {
    console.error(err);

    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

router.get(
  '/medical-results',
  authMiddleware,
  async (req, res) => {
    try {

     const results = await pool.query(`
  SELECT
    id,
    patient_phone,
    title,
    file_url,
    result_type,
    created_at
  FROM medical_results
  ORDER BY created_at DESC
`);

      res.json({
        success: true,
        results: results.rows,
      });

    } catch (err) {
      console.log(err);
      res.status(500).json({
        success: false,
        message: 'Erreur serveur',
      });
    }
  }
);


router.post(
   '/medical-results/upload',
  auth,
  upload.single('file'),
  async (req, res) => {
    try {
      const { patientPhone, title, resultType } = req.body;

      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: 'Aucun fichier reçu',
        });
      }

      const fileUrl = `/uploads/medical-results/${req.file.filename}`;

      const result = await pool.query(
        `
        INSERT INTO medical_results
        (
          patient_phone,
          title,
          file_url,
          result_type,
          uploaded_by
        )
        VALUES ($1,$2,$3,$4,$5)
        RETURNING *
        `,
        [
          patientPhone,
          title,
          fileUrl,
          resultType,
          req.userId,
        ]
      );
console.log(results);
      res.json({
        success: true,
        message: 'Document médical ajouté',
        result: result.rows[0],
      });
    } catch (error) {
      console.error('UPLOAD MEDICAL RESULT ERROR:', error);

      res.status(500).json({
        success: false,
        message: 'Erreur serveur',
      });
    }
  }
);

router.post('/medical-results', auth, async (req, res) => {
  try {
    const {
      patientPhone,
      title,
      fileUrl,
      resultType,
    } = req.body;

    await pool.query(
      `
      INSERT INTO medical_results
      (
        patient_phone,
        title,
        file_url,
        result_type,
        uploaded_by
      )
      VALUES ($1,$2,$3,$4,$5)
      `,
      [
        patientPhone,
        title,
        fileUrl,
        resultType,
        req.userId,
      ]
    );

    res.json({
      success: true,
      message: 'Résultat ajouté',
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});


router.post('/doctor-availability', auth, async (req, res) => {
  try {
    const {
      doctorName,
      clinicName,
      availableDate,
      startTime,
      endTime,
    } = req.body;

    const result = await pool.query(
      `
      INSERT INTO doctor_availabilities
      (
        doctor_id,
        doctor_name,
        clinic_name,
        available_date,
        start_time,
        end_time
      )
      VALUES ($1,$2,$3,$4,$5,$6)
      RETURNING *
      `,
      [
        req.userId,
        doctorName,
        clinicName,
        availableDate,
        startTime,
        endTime,
      ]
    );

    res.json({
      success: true,
      availability: result.rows[0],
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});


router.get('/doctor-availability/:doctorId', auth, async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT *
      FROM doctor_availabilities
      WHERE doctor_id = $1
      ORDER BY available_date ASC
      `,
      [req.params.doctorId]
    );

    res.json({
      success: true,
      availabilities: result.rows,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

router.get('/doctor-availability', auth, async (req, res) => {
  try {
   const result = await pool.query(`
  SELECT da.*
  FROM doctor_availabilities da
  WHERE NOT EXISTS (
    SELECT 1
    FROM medical_appointments ma
    WHERE ma.doctor_id = da.doctor_id
    AND ma.appointment_date = da.available_date
    AND ma.appointment_time = da.start_time
    AND ma.status = 'confirmed'
  )
  ORDER BY da.available_date ASC
`);
console.log('AVAILABILITIES:', result.rows);
    res.json({
      success: true,
      availabilities: result.rows,
    });
  } catch (error) {
    console.error('GET AVAILABILITY ERROR:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

router.get('/doctor-unavailability', auth, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT *
      FROM doctor_unavailabilities
      ORDER BY unavailable_date ASC
    `);

    res.json({
      success: true,
      unavailabilities: result.rows,
    });
  } catch (error) {
    console.error('GET UNAVAILABILITY ERROR:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

router.post('/doctor-unavailability', auth, async (req, res) => {
  try {
    const {
      doctor_name,
      clinic_name,
      unavailable_date,
      reason,
    } = req.body;

    const result = await pool.query(
      `
      INSERT INTO doctor_unavailabilities
      (
        doctor_id,
        doctor_name,
        clinic_name,
        unavailable_date,
        reason
      )
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
      `,
      [
        req.userId,
        doctor_name,
        clinic_name,
        unavailable_date,
        reason,
      ]
    );

    res.json({
      success: true,
      unavailability: result.rows[0],
    });
  } catch (error) {
    console.error('UNAVAILABILITY ERROR:', error);

    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

router.get('/my-appointments', auth, async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT *
      FROM medical_appointments
      WHERE patient_id = $1
      ORDER BY appointment_date ASC, appointment_time ASC
      `,
      [req.userId]
    );

    res.json({
      success: true,
      appointments: result.rows,
    });
  } catch (error) {
    console.error('MY APPOINTMENTS ERROR:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

router.post('/subscribe-wallet', authMiddleware, async (req, res) => {
  const client = await pool.connect();

  try {
    const userId = req.userId;
    const { planType, pin } = req.body;

    const plans = {
      monthly: { amount: 35, months: 1 },
      quarterly: { amount: 100, months: 3 },
      yearly: { amount: 350, months: 12 },
    };

    const plan = plans[planType];

    if (!plan) {
      return res.status(400).json({
        success: false,
        message: 'Plan invalide',
      });
    }

    await client.query('BEGIN');

    const userResult = await client.query(
      `
      SELECT id, balance, pin
      FROM users
      WHERE id = $1
      FOR UPDATE
      `,
      [userId]
    );

    if (userResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        message: 'Utilisateur introuvable',
      });
    }

    const user = userResult.rows[0];

    if (String(user.pin) !== String(pin)) {
      await client.query('ROLLBACK');
      return res.status(401).json({
        success: false,
        message: 'PIN incorrect',
      });
    }

    if (Number(user.balance) < plan.amount) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Solde insuffisant',
      });
    }

    const endDateResult = await client.query(
      `SELECT NOW() + ($1 || ' months')::interval AS end_date`,
      [plan.months]
    );

    const endDate = endDateResult.rows[0].end_date;

   const updateUserResult = await client.query(
  `
  UPDATE users
  SET 
    balance = balance - $1,
    subscription_status = 'active',
    subscription_end_date = $2
  WHERE id = $3
  RETURNING balance
  `,
  [plan.amount, endDate, userId]
);

const newBalance = updateUserResult.rows[0].balance;

    await client.query(
      `
      INSERT INTO professional_subscriptions (
        professional_id,
        plan_type,
        amount,
        payment_status,
        start_date,
        end_date
      )
      VALUES ($1, $2, $3, 'paid', NOW(), $4)
      `,
      [userId, planType, plan.amount, endDate]
    );

    await client.query('COMMIT');

    await client.query(
  `
  INSERT INTO transactions
  (sender_id, amount, type, description, status, created_at)
  VALUES ($1, $2, $3, $4, $5, NOW())
  `,
  [
    userId,
    plan.amount,
    'subscription',
    `Abonnement FG Santé Pro ${planType}`,
    'completed',
  ]
);

return res.json({
  success: true,
  message: 'Abonnement activé',
  amount: plan.amount,
  newBalance,
  endDate,
});

  } catch (err) {
    await client.query('ROLLBACK');

    console.error('SUBSCRIBE WALLET ERROR:', err);

    return res.status(500).json({
      success: false,
      message: 'Erreur abonnement wallet',
      error: err.toString(),
    });
  } finally {
    client.release();
  }
});

router.post('/appointments/:id/cancel', auth, async (req, res) => {
  try {
    const { id } = req.params;

    await pool.query(
      `
      UPDATE medical_appointments
      SET status = 'cancelled'
      WHERE id = $1 AND patient_id = $2
      `,
      [id, req.userId]
    );

    res.json({
      success: true,
      message: 'Rendez-vous annulé',
    });
  } catch (error) {
    console.error('CANCEL APPOINTMENT ERROR:', error);

    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

router.get('/prescriptions', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT *
      FROM prescriptions
      WHERE patient_id = $1
      ORDER BY created_at DESC
      `,
      [req.userId]
    );

for (const prescription of prescriptions) {
  const itemsResult = await pool.query(
    `
    SELECT medication, dosage, duration, instructions
    FROM prescription_items
    WHERE prescription_id = $1
    ORDER BY id ASC
    `,
    [prescription.id]
  );

  prescription.items = itemsResult.rows;
}

    res.json({
      success: true,
      prescriptions,
    });

  } catch (err) {
    console.error(err);

    res.status(500).json({
      success: false,
      message: 'Erreur récupération prescriptions'
    });
  }
});

router.post('/book-appointment', auth, async (req, res) => {
  try {

    const {
      doctorId,
      doctorName,
      clinicName,
      appointmentDate,
      appointmentTime,
    } = req.body;

    const patientResult = await pool.query(
      'SELECT name FROM users WHERE id = $1',
      [req.userId]
    );

    const patientName =
      patientResult.rows[0]?.name || 'Patient';

    const result = await pool.query(
      `
      INSERT INTO medical_appointments
      (
        patient_id,
        doctor_id,
        patient_name,
        doctor_name,
        clinic_name,
        appointment_date,
        appointment_time,
        status
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
      RETURNING *
      `,
      [
        req.userId,
        doctorId,
        patientName,
        doctorName,
        clinicName,
        appointmentDate,
        appointmentTime,
        'confirmed',
      ]
    );
console.log('PRESCRIPTION CREATED:', result.rows[0]);

    res.json({
      success: true,
      appointment: result.rows[0],
    });

  } catch (error) {

    console.error(
      'BOOK APPOINTMENT ERROR:',
      error,
    );

    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

router.get('/medical-records/patient/:patientId', authMiddleware, async (req, res) => {
  try {
    const { patientId } = req.params;

    const result = await pool.query(
      `
      SELECT *
      FROM medical_records
      WHERE patient_id = $1
      ORDER BY created_at DESC
      `,
      [patientId]
    );

    res.json({
      success: true,
      records: result.rows,
    });
  } catch (err) {
    console.log('GET PATIENT MEDICAL RECORDS ERROR:', err);
    res.status(500).json({
      success: false,
      message: 'Erreur récupération dossier médical',
    });
  }
});

// =============================
// AJOUTER PRESCRIPTION
// =============================
router.post('/prescriptions', auth, async (req, res) => {
  try {
console.log('PRESCRIPTION BODY:', req.body);
console.log('PRESCRIPTION USER:', req.userId);

    const {
      patientName,
      patientPhone,
      medication,
      dosage,
      duration,
      instructions,
      doctorName,
    } = req.body;

    const doctor_id = req.userId;
const appointment_id = req.body.appointmentId;

const appointmentData = await pool.query(
`
SELECT
a.patient_id,
u.full_name AS patient_name,
u.phone,
d.full_name AS doctor_name
FROM appointments a
LEFT JOIN users u
ON a.patient_id = u.id
LEFT JOIN users d
ON d.id = $1
WHERE a.id = $2
`,
[doctor_id, appointment_id]
);

const patientInfo = appointmentData.rows[0];

if (!patientInfo) {
  return res.status(404).json({
    success: false,
    message: 'Rendez-vous introuvable',
  });
}

const result = await pool.query(
`
INSERT INTO prescriptions(
patient_id,
patient_name,
patient_phone,
doctor_id,
doctor_name,
appointment_id,
medication,
dosage,
duration,
instructions
)
VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
RETURNING *
`,
[
patientInfo.patient_id,
patientInfo.patient_name,
patientInfo.phone,
doctor_id,
patientInfo.doctor_name,
appointment_id,
medication,
dosage,
duration,
instructions
]
);

const prescription = result.rows[0];

await pool.query(
  `
  INSERT INTO notifications(
    user_id,
    title,
    message,
    type,
    is_read
  )
  VALUES($1,$2,$3,$4,false)
  `,
  [
    1, // ID admin lan
    'Nouvelle prescription 💊',
    `${patientInfo.patient_name} resevwa yon nouvo preskripsyon: ${prescription.medication}`,
    'prescription'
  ]
);

console.log('PRESCRIPTION NOTIFICATION CREATED');

    res.json({
      success: true,
      message: 'Prescription ajoutée',
      prescription: result.rows[0],
    });
  } catch (error) {
    console.error('PRESCRIPTION ERROR:', error);

    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

// =============================
// RECUPERER PRESCRIPTIONS
// =============================
router.get('/my-prescriptions', auth, async (req, res) => {
  try {

    const userId = req.userId;

    console.log('USER ID:', userId);

    const result = await pool.query(
      `
      SELECT *
      FROM prescriptions
      WHERE patient_id = $1
      ORDER BY created_at DESC
      `,
      [userId]
    );

    console.log('PRESCRIPTIONS:', result.rows);

    res.json({
      success: true,
      prescriptions: result.rows,
    });

  } catch(error){
    console.error(error);
  }
});

router.get('/admin/prescriptions', auth, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
p.*,
u.full_name AS patient_name
FROM prescriptions p
LEFT JOIN users u
ON p.patient_id = u.id
ORDER BY p.created_at DESC
    `);

    res.json({
      success: true,
      prescriptions: result.rows,
    });
  } catch (error) {
    console.error('ADMIN PRESCRIPTIONS ERROR:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur récupération prescriptions admin',
    });
  }
});
// =============================
// GET APPOINTMENTS
// =============================
router.get('/appointments', auth, async (req, res) => {
  try {
    const result = await pool.query(
  `
  SELECT
    a.*,
    a.patient_id,
    u.name AS patient_name,
    u.phone AS patient_phone
  FROM appointments a
  LEFT JOIN users u ON u.id = a.patient_id
  WHERE a.patient_id = $1
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




router.post('/patient-profile', auth, async (req, res) => {

 console.log('PROFILE BODY:', req.body);
console.log('PROFILE USER:', req.userId); 
  try {
    const {
      fullName,
      phone,
      gender,
      dateOfBirth,
      bloodGroup,
      allergies,
      chronicDiseases,
      emergencyContactName,
      emergencyContactPhone,
      address
    } = req.body;

    const existingPatient = await pool.query(
      'SELECT * FROM patients WHERE user_id = $1',
      [req.userId]
    );

    if (existingPatient.rows.length > 0) {

      await pool.query(
        `
        UPDATE patients
        SET
          full_name = $1,
          phone = $2,
          gender = $3,
          date_of_birth = $4,
          blood_group = $5,
          allergies = $6,
          chronic_diseases = $7,
          emergency_contact_name = $8,
          emergency_contact_phone = $9,
          address = $10
        WHERE user_id = $11
        `,
        [
          fullName,
          phone,
          gender,
          dateOfBirth,
          bloodGroup,
          allergies,
          chronicDiseases,
          emergencyContactName,
          emergencyContactPhone,
          address,
          req.userId
        ]
      );

    } else {

      await pool.query(
        `
        INSERT INTO patients (
          user_id,
          full_name,
          phone,
          gender,
          date_of_birth,
          blood_group,
          allergies,
          chronic_diseases,
          emergency_contact_name,
          emergency_contact_phone,
          address
        )
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
        `,
        [
          req.userId,
          fullName,
          phone,
          gender,
          dateOfBirth,
          bloodGroup,
          allergies,
          chronicDiseases,
          emergencyContactName,
          emergencyContactPhone,
          address
        ]
      );
    }

    res.json({
      success: true,
      message: 'Profil médical enregistré'
    });

  } catch (error) {
    console.error('patient profile error:', error);

    res.status(500).json({
      success: false,
      message: 'Erreur serveur'
    });
  }
});


router.post('/records', auth, upload.single('file'), async (req, res) => {
  try {
    const patientId = req.body.patientId || req.body.patient_id;
    const title = req.body.title;
    const type = req.body.category || req.body.type;
    const description = req.body.notes || req.body.description;
    const doctorName = req.body.doctorName || req.body.doctor_name;
    const clinicName = req.body.clinicName || req.body.clinic_name;
    const fileUrl = req.file ? `/uploads/medical/${req.file.filename}` : null;

    const result = await pool.query(
      `
      INSERT INTO medical_records
      (
        patient_id,
        title,
        type,
        description,
        doctor_name,
        clinic_name,
        file_url
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7)
      RETURNING *
      `,
      [
        patientId,
        title,
        type,
        description,
        doctorName,
        clinicName,
        fileUrl,
      ]
    );

    return res.json({
      success: true,
      message: 'Résultat ajouté',
      record: result.rows[0],
    });

  } catch (err) {
    console.error('ADD MEDICAL RECORD ERROR:', err.message);

    return res.status(500).json({
      success: false,
      message: err.message,
    });
  }
});

router.get('/records', auth, async (req, res) => {
  try {
    const patientResult = await pool.query(
      'SELECT id FROM patients WHERE user_id = $1',
      [req.userId]
    );

    if (patientResult.rows.length === 0) {
      return res.json({
        success: true,
        records: [],
      });
    }

    const patientId = patientResult.rows[0].id;

    const recordsResult = await pool.query(
      `
      SELECT *
      FROM medical_records
      WHERE patient_id = $1
      ORDER BY created_at DESC
      `,
      [patientId]
    );

    res.json({
      success: true,
      records: recordsResult.rows,
    });
  } catch (error) {
    console.error('get medical records error:', error);

    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

router.get('/patient-records/:phone', auth, async (req, res) => {
  try {
    const { phone } = req.params;

    const patientResult = await pool.query(
      'SELECT id FROM patients WHERE phone = $1',
      [phone]
    );

    if (patientResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Patient introuvable',
      });
    }

    const patientId = patientResult.rows[0].id;

    const records = await pool.query(
      `
      SELECT *
      FROM medical_records
      WHERE patient_id = $1
      ORDER BY created_at DESC
      `,
      [patientId]
    );

    res.json({
      success: true,
      records: records.rows,
    });

  } catch (error) {
    console.error(error);

    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

router.get('/records', auth, async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT *
      FROM medical_records
      ORDER BY created_at DESC
      `
    );

    res.json({
      success: true,
      records: result.rows,
    });

  } catch (error) {
    console.error('get records error:', error);

    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

router.get('/patient-profile', auth, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT *
       FROM patients
       WHERE user_id = $1`,
      [req.userId]
    );

    res.json({
      success: true,
      profile: result.rows[0] || null,
    });
  } catch (error) {
    console.error('get patient profile error:', error);

    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

router.get('/admin/medical-records', auth, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        mr.*,
        u.full_name AS patient_name
      FROM medical_records mr
      LEFT JOIN users u ON mr.patient_id = u.id
      ORDER BY mr.created_at DESC
    `);

    res.json({
      success: true,
      records: result.rows,
    });
  } catch (error) {
    console.error('ADMIN MEDICAL RECORDS ERROR:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur récupération résultats médicaux admin',
    });
  }
});

router.post('/records', auth, async (req, res) => {
    console.log('BODY:', req.body);
console.log('USER:', req.userId);
  try {
    const {
      patientPhone,
      title,
      category,
      notes,
      doctorName,
      clinicName,
    } = req.body;

    if (!patientPhone || !title) {
      return res.status(400).json({
        success: false,
        message: 'Téléphone patient et titre obligatoires',
      });
    }

    const patientResult = await pool.query(
      `SELECT id FROM users WHERE phone = $1`,
      [patientPhone]
    );

    if (patientResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Patient introuvable',
      });
    }

    const patientId = patientResult.rows[0].id;

    const result = await pool.query(
      `INSERT INTO medical_records
       (user_id, title, category, notes, doctor_name, clinic_name, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, NOW())
       RETURNING *`,
      [
        patientId,
        title,
        category || 'Examen',
        notes || '',
        doctorName || 'Professionnel de santé',
        clinicName || 'FG Santé',
      ]
    );

    res.json({
      success: true,
      message: 'Résultat médical ajouté au dossier patient',
      record: result.rows[0],
    });
  } catch (err) {
    console.error('add medical record error:', err);

    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

// ===============================
// AJOUTER RENDEZ-VOUS
// ===============================
router.post('/appointments', auth, async (req, res) => {
  try {
    const {
      patientPhone,
      patientName,
      doctorName,
      clinicName,
      appointmentDate,
      appointmentTime,
      reason
    } = req.body;

    const result = await pool.query(
      `
      INSERT INTO medical_appointments
      (
        patient_phone,
        patient_name,
        doctor_name,
        clinic_name,
        appointment_date,
        appointment_time,
        reason
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7)
      RETURNING *
      `,
      [
        patientPhone,
        patientName,
        doctorName,
        clinicName,
        appointmentDate,
        appointmentTime,
        reason
      ]
    );

    res.json({
      success: true,
      appointment: result.rows[0]
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur'
    });
  }
});


// ===============================
// RECUPERER RENDEZ-VOUS
// ===============================
router.get('/appointments/:phone', auth, async (req, res) => {
  try {

    const { phone } = req.params;

    const result = await pool.query(
      `
      SELECT *
      FROM medical_appointments
      WHERE patient_phone = $1
      ORDER BY appointment_date DESC
      `,
      [phone]
    );

    res.json({
      success: true,
      appointments: result.rows
    });

  } catch (err) {
    console.error(err);

    res.status(500).json({
      success: false,
      message: 'Erreur serveur'
    });
  }
});

router.get('/medical-records/patient/:patientId', async (req, res) => {
  try {
    const { patientId } = req.params;

    const result = await pool.query(
      `
      SELECT *
      FROM medical_records
      WHERE patient_id = $1
      ORDER BY created_at DESC
      `,
      [patientId]
    );

    res.json(result.rows);

  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

router.get('/professionals/pending', async (req, res) => {
  try {
    console.log('ROUTE PENDING HIT');

    const result = await pool.query(
      `
      SELECT id, name, email, phone, professional_status
      FROM users
      WHERE professional_status = $1
      `,
      ['pending']
    );

    return res.json({
      success: true,
      professionals: result.rows,
    });

  } catch (error) {
    console.error('Erreur pending professionals:', error);

    return res.status(500).json({
      success: false,
      professionals: [],
      message: error.message,
    });
  }
});

router.get('/notifications', authMiddleware, async (req, res) => {
  try {

    console.log('USER ID:', req.userId);

    const result = await pool.query(
      `
      SELECT *
      FROM notifications
      WHERE user_id = $1
      ORDER BY created_at DESC
      `,
      [req.userId]
    );

    console.log('ROWS:', result.rows.length);

    return res.json({
      success: true,
      notifications: result.rows,
    });

  } catch (error) {

    console.log('FULL NOTIFICATION ERROR:');
    console.log(error);

    return res.status(500).json({
      success: false,
      notifications: [],
      message: error.toString(),
    });

  }
});


router.put('/professionals/:id/approve', auth, async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      `
      UPDATE users
      SET professional_status = 'approved'
      WHERE id = $1
      RETURNING id, name, email, professional_status
      `,
      [id]
    );

    return res.json({
      success: true,
      professional: result.rows[0],
    });
  } catch (error) {
    console.error('Erreur approval professionnel:', error);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
});

router.put('/professionals/:id/reject', auth, async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      `
      UPDATE users
      SET professional_status = 'rejected'
      WHERE id = $1
      RETURNING id, name, email, professional_status
      `,
      [id]
    );

    return res.json({
      success: true,
      professional: result.rows[0],
    });
  } catch (error) {
    console.error('Erreur rejet professionnel:', error);
    return res.status(500).json({ message: 'Erreur serveur' });
  }
});

router.get('/my-prescriptions', authMiddleware, async (req, res) => {
  try {
    const patientId = req.userId;

    const result = await pool.query(
      `
      SELECT *
      FROM prescriptions
      WHERE patient_id = $1
      ORDER BY id DESC
      `,
      [patientId]
    );

    res.json({
      success: true,
      prescriptions: result.rows,
    });

  } catch (err) {
    console.error('PRESCRIPTION ERROR:', err);

    res.status(500).json({
      success: false,
      message: 'Erreur chargement prescriptions',
    });
  }
});

module.exports = router;