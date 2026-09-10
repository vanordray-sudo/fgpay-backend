const express = require('express');
const router = express.Router();

const pool = require('../db');
const authMiddleware = require('../middleware/authMiddleware');
const multer = require('multer');
const path = require('path');
const fs = require('fs');


const uploadPath = path.join(__dirname, '..', 'uploads', 'medical');

if (!fs.existsSync(uploadPath)) {
  fs.mkdirSync(uploadPath, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadPath);
  },

 filename: (req, file, cb) => {
  const originalName = Buffer.from(file.originalname, 'latin1').toString('utf8');

  const cleanName = originalName
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/æ/g, 'ae')
    .replace(/Æ/g, 'AE')
    .replace(/\s+/g, '_')
    .replace(/[^a-zA-Z0-9._-]/g, '');

    cb(null, Date.now() + '-' + cleanName);
}
});

const upload = multer({ storage });


// =============================
// CREATE MEDICAL RECORD
// =============================
router.post('/create', authMiddleware, upload.single('file'), async (req, res) => {
  try {
    const fileUrl = req.file
      ? `/uploads/medical/${req.file.filename}`
      : null;

    const doctorId = req.userId;

    const {
      patient_id,
      title,
      type,
      description,
      doctor_name,
      clinic_name,
    } = req.body;

    console.log('CREATE MEDICAL RECORD:', req.body);
    console.log('FILE URL:', fileUrl);
   const verificationCode =
  'FG-' + Date.now().toString();
   const result = await pool.query(
`
INSERT INTO medical_records
(
  patient_id,
  user_id,
  title,
  type,
  description,
  doctor_name,
  clinic_name,
  file_url,
  verification_code
)
VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
RETURNING *
`,
[
  patient_id,
  doctorId,
  title,
  type,
  description,
  doctor_name,
  clinic_name,
  fileUrl,
  verificationCode,
]
);


try {
 const patientUserResult = await pool.query(
  `
  SELECT patient_id AS user_id
  FROM appointments
  WHERE id = $1
  LIMIT 1
  `,
  [appointmentId]
);

  if (patientUserResult.rows.length > 0) {
    const patientUserId = patientUserResult.rows[0].user_id;

    await pool.query(
      `
      INSERT INTO notifications (user_id, title, message, type)
      VALUES ($1, $2, $3, $4)
      `,
      [
        patientUserId,
        'Nouveau résultat médical',
        `Le résultat "${title}" est maintenant disponible`,
        'medical_result'
      ]
    );
  }
} catch (notifError) {
  console.log('Notification non créée:', notifError.message);
}

    res.status(201).json({
      success: true,
      record: result.rows[0],
    });
 } catch (error) {
  console.error('========================');
  console.error('CREATE MEDICAL RECORD ERROR');
  console.error(error);
  console.error('MESSAGE:', error.message);

  if (error.detail) {
    console.error('DETAIL:', error.detail);
  }

  console.error('========================');

  res.status(500).json({
    success: false,
    message: error.message,
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
// GET PATIENT RECORDS
// =============================
router.get('/patient', authMiddleware, async (req, res) => {
  try {
    const patientId = req.userId;

    const result = await pool.query(
      `
      SELECT
        mr.*,
        u.email AS doctor_name
      FROM medical_records mr
      LEFT JOIN users u
      ON mr.doctor_id = u.id
      WHERE mr.patient_id = $1
      ORDER BY mr.created_at DESC
      `,
      [patientId]
    );

    res.json({
      success: true,
      records: result.rows,
    });

  } catch (error) {
    console.error('GET PATIENT RECORDS ERROR:', error);

    res.status(500).json({
      success: false,
      message: 'Erreur récupération dossiers',
    });
  }
});

router.get('/medical-records/patient', authMiddleware, async (req, res) => {
  try {
    const patient_id = req.userId;

    const result = await pool.query(
      `
      SELECT *
      FROM medical_records
      WHERE patient_id = $1
      ORDER BY created_at DESC
      `,
      [patient_id]
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

// VERIFY MEDICAL RECORD
router.get('/verify/:code', async (req, res) => {
  try {
    const { code } = req.params;

    const result = await pool.query(
      `
      SELECT
        id,
        title,
        type,
        description,
        doctor_name,
        clinic_name,
        verification_code,
        created_at
      FROM medical_records
      WHERE verification_code = $1
      `,
      [code]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        valid: false,
        message: 'Document introuvable',
      });
    }

    res.json({
      success: true,
      valid: true,
      record: result.rows[0],
    });

  } catch (error) {
    console.log('VERIFY RECORD ERROR:', error);

    res.status(500).json({
      success: false,
      valid: false,
      message: 'Erreur serveur',
    });
  }
});

router.post('/', authMiddleware, async (req,res)=>{

try{

const {
patientId,
appointmentId,
diagnosis,
symptoms,
treatment,
notes,
bloodPressure,
temperature,
weight
} = req.body;

const result = await pool.query(
`
INSERT INTO medical_records
(
patient_id,
appointment_id,
doctor_id,
diagnosis,
symptoms,
treatment,
notes,
blood_pressure,
temperature,
weight
)

VALUES
($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)

RETURNING *
`,
[
patientId,
appointmentId,
req.userId,
diagnosis,
symptoms,
treatment,
notes,
bloodPressure,
temperature,
weight
]
);

res.json({
success:true,
record:result.rows[0]
});

}catch(err){

console.log(err);

res.status(500).json({
success:false,
message:err.message
});

}

});

// =============================
// GET MY HEALTH MEDICAL RECORD
// =============================
router.get(
  '/health-profile/me',
  authMiddleware,
  async (req, res) => {
    try {
      const patientId = req.userId;

      if (!patientId) {
        return res.status(400).json({
          success: false,
          message: 'Utilisateur introuvable.',
        });
      }

      const result = await pool.query(
        `
        SELECT *
        FROM health_medical_records
        WHERE patient_id = $1
        LIMIT 1
        `,
        [patientId]
      );

      return res.status(200).json({
        success: true,
        medical_record:
          result.rows.length > 0
            ? result.rows[0]
            : null,
      });

    } catch (error) {
      console.error(
        'GET HEALTH MEDICAL RECORD ERROR:',
        error
      );

      return res.status(500).json({
        success: false,
        message: error.message,
      });
    }
  }
);

// =============================
// CREATE / UPDATE HEALTH PROFILE
// =============================
router.put(
  '/health-profile/me',
  authMiddleware,
  async (req, res) => {
    try {
      const patientId = req.userId;

      if (!patientId) {
        return res.status(400).json({
          success: false,
          message: 'Utilisateur introuvable.',
        });
      }

      const {
        country_code,
        preferred_language,
        blood_type,
        allergies,
        chronic_conditions,
        medical_history,
        surgical_history,
        current_treatments,
        emergency_contact_name,
        emergency_contact_phone,
        emergency_contact_relation,
      } = req.body;

      const result = await pool.query(
        `
        INSERT INTO health_medical_records (
          patient_id,
          country_code,
          preferred_language,
          blood_type,
          allergies,
          chronic_conditions,
          medical_history,
          surgical_history,
          current_treatments,
          emergency_contact_name,
          emergency_contact_phone,
          emergency_contact_relation
        )
        VALUES (
          $1,$2,$3,$4,$5,$6,
          $7,$8,$9,$10,$11,$12
        )

        ON CONFLICT (patient_id)

        DO UPDATE SET
          country_code = EXCLUDED.country_code,
          preferred_language = EXCLUDED.preferred_language,
          blood_type = EXCLUDED.blood_type,
          allergies = EXCLUDED.allergies,
          chronic_conditions = EXCLUDED.chronic_conditions,
          medical_history = EXCLUDED.medical_history,
          surgical_history = EXCLUDED.surgical_history,
          current_treatments = EXCLUDED.current_treatments,
          emergency_contact_name =
            EXCLUDED.emergency_contact_name,
          emergency_contact_phone =
            EXCLUDED.emergency_contact_phone,
          emergency_contact_relation =
            EXCLUDED.emergency_contact_relation,
          updated_at = NOW()

        RETURNING *
        `,
        [
          patientId,
          country_code,
          preferred_language,
          blood_type,
          allergies,
          chronic_conditions,
          medical_history,
          surgical_history,
          current_treatments,
          emergency_contact_name,
          emergency_contact_phone,
          emergency_contact_relation,
        ]
      );

      return res.status(200).json({
        success: true,
        medical_record: result.rows[0],
      });

    } catch (error) {
      console.error(
        'SAVE HEALTH MEDICAL RECORD ERROR:',
        error
      );

      return res.status(500).json({
        success: false,
        message: error.message,
      });
    }
  }
);

module.exports=router;