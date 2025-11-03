import { NextResponse } from 'next/server';
import { pool } from '@/lib/db';

export async function POST(req: Request) {
  try {
    const { playerId, playerName } = await req.json();

    const [result]: any = await pool.execute(
      'INSERT INTO game_session (player_id, player_name) VALUES (?, ?)',
      [playerId, playerName]
    );

    const [rows]: any = await pool.query(
      'SELECT * FROM game_session WHERE session_id = ?',
      [result.insertId]
    );

    return NextResponse.json(rows[0], { status: 201 });
  } catch (error) {
    console.error('Error creating session:', error);
    return NextResponse.json(
      { error: 'Failed to create session' },
      { status: 500 }
    );
  }
}

export async function PUT(req: Request) {
  try {
    const { sessionId, accusedCharacterId } = await req.json();

    // Get session info
    const [sessionRows]: any = await pool.query(
      'SELECT player_id, started_at FROM game_session WHERE session_id = ?',
      [sessionId]
    );

    if (!sessionRows.length) {
      return NextResponse.json(
        { error: 'Session not found' },
        { status: 404 }
      );
    }

    const playerId = sessionRows[0].player_id;
    const startedAt = new Date(sessionRows[0].started_at);
    const timeSpentSeconds = Math.floor((Date.now() - startedAt.getTime()) / 1000);

    // Check if accused character is killer
    const [characterRows]: any = await pool.query(
      'SELECT is_killer FROM game_character WHERE character_id = ?',
      [accusedCharacterId]
    );

    const isKiller = characterRows.length > 0 ? Boolean(characterRows[0].is_killer) : false;
    const finalScore = isKiller ? 500 : 100;

    // Update session
    await pool.execute(
      `UPDATE game_session 
       SET status = 'completed',
           ended_at = NOW(),
           total_score = ?,
           time_spent_seconds = ?,
           accused_character_id = ?,
           is_correct_accusation = ?
       WHERE session_id = ?`,
      [finalScore, timeSpentSeconds, accusedCharacterId, isKiller ? 1 : 0, sessionId]
    );

    // Update player
    await pool.execute(
      `UPDATE player
       SET total_score = total_score + ?,
           games_played = games_played + 1,
           last_played = NOW()
       WHERE player_id = ?`,
      [finalScore, playerId]
    );

    // Return response
    return NextResponse.json({
      session_id: sessionId,
      final_score: finalScore,
      is_correct: isKiller,
      message: isKiller
        ? 'Correct! You found the killer!'
        : 'Wrong accusation!'
    });
  } catch (error) {
    console.error('PUT Error:', error);
    return NextResponse.json(
      { error: 'Failed to end session' },
      { status: 500 }
    );
  }
}
