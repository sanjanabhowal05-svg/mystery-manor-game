import { NextResponse } from 'next/server';
import { pool } from '@/lib/db';

export async function GET(req: Request) {
  try {
    const { searchParams } = new URL(req.url);
    const type = searchParams.get('type');
    const limit = Number(searchParams.get('limit') ?? 10);
    
    if (type === 'leaderboard') {
      const [rows]: any = await pool.query(
        `SELECT player_id, name, session_id, total_score, 
                time_spent_seconds, ended_at, rank_position
         FROM leaderboard_view
         ORDER BY rank_position
         LIMIT ?`,
        [limit]
      );
      
      return NextResponse.json(rows);
    }
    
    return NextResponse.json(
      { error: 'Invalid type parameter' },
      { status: 400 }
    );
  } catch (error) {
    console.error('Error fetching data:', error);
    return NextResponse.json(
      { error: 'Failed to fetch data' },
      { status: 500 }
    );
  }
}
