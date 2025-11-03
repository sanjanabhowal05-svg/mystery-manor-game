import { NextResponse } from 'next/server';
import { pool } from '@/lib/db';

export async function POST(req: Request) {
  try {
    const { name, email } = await req.json();
    
    const [result]: any = await pool.execute(
      'INSERT INTO player (name, email) VALUES (?, ?)',
      [name, email ?? null]
    );
    
    const [rows]: any = await pool.query(
      'SELECT * FROM player WHERE player_id = ?',
      [result.insertId]
    );
    
    return NextResponse.json(rows[0], { status: 201 });
  } catch (error) {
    console.error('Error creating player:', error);
    return NextResponse.json(
      { error: 'Failed to create player' },
      { status: 500 }
    );
  }
}
