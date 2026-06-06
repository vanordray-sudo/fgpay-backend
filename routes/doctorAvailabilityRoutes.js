const express = require('express');
const router = express.Router();
const pool = require('../db');
const authMiddleware = require('../middleware/authMiddleware');


// =============================
// Ajouter disponibilité
// =============================
router.post('/add', authMiddleware, async (req, res) => {
  try {
    const {
      available_date,
      start_time,
      end_time,
    } = req.body;

    const doctorId = req.userId;

    if (!available_date || !start_time || !end_time) {
      return res.status(400).json({
        error: 'Tous les champs sont requis',
      });
    }

    const result = await pool.query(
      `
      INSERT INTO doctor_availabilities
      (
        doctor_id,
        available_date,
        start_time,
        end_time
      )
      VALUES ($1, $2, $3, $4)
      RETURNING *
      `,
      [
        doctorId,
        available_date,
        start_time,
        end_time,
      ]
    );

    res.json({
      success: true,
      availability: result.rows[0],
    });

  } catch (error) {
    console.error('Erreur ajout disponibilité:', error);

    res.status(500).json({
      error: 'Erreur serveur',
    });
  }
});


// =============================
// Mes disponibilités
// =============================
router.get('/mine', authMiddleware, async (req, res) => {
  try {

    const doctorId = req.userId;

    const result = await pool.query(
      `
      SELECT *
      FROM doctor_availabilities
      WHERE doctor_id = $1
      ORDER BY available_date ASC
      `,
      [doctorId]
    );

    res.json(result.rows);

  } catch (error) {
    console.error(error);

    res.status(500).json({
      error: 'Erreur serveur',
    });
  }
});


// =============================
// Supprimer disponibilité
// =============================
router.delete('/:id', authMiddleware, async (req, res) => {
  try {

    const { id } = req.params;

    await pool.query(
      `
      DELETE FROM doctor_availabilities
      WHERE id = $1
      `,
      [id]
    );

    res.json({
      success: true,
    });

  } catch (error) {
    console.error(error);

    res.status(500).json({
      error: 'Erreur serveur',
    });
  }
});

module.exports = router;