"use client";

import { useQuery } from "@tanstack/react-query";

export default function Home() {
  const { data: leaderboard } = useQuery({
    queryKey: ["leaderboard"],
    queryFn: async () => {
      const res = await fetch("/api/game/data?type=leaderboard&limit=15");
      if (!res.ok) return [];
      return res.json();
    },
  });

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 text-white">
      {/* Header/Hero */}
      <div className="relative overflow-hidden px-4 py-20 sm:px-6 sm:py-32">
        <div className="mx-auto max-w-4xl text-center">
          <h1 className="text-5xl sm:text-7xl font-bold mb-4">
            <span className="text-yellow-400">Mystery Manor</span>
          </h1>
          <p className="text-xl sm:text-2xl text-slate-300 mb-8">
            Uncover the truth. Find the killer. Solve the mystery.
          </p>
          <p className="text-base sm:text-lg text-slate-400 mb-12">
            A thrilling detective adventure where every clue matters. Explore
            the manor, interview suspects, and solve puzzles to find Lord
            Blackwood&apos;s killer.
          </p>

          <a
            href="/game"
            className="inline-block bg-yellow-500 hover:bg-yellow-600 text-black font-bold text-lg px-8 py-4 rounded-lg shadow-lg transform hover:scale-105 transition"
          >
            🕵️ Start Investigation
          </a>
        </div>

        {/* Decorative elements */}
        <div className="absolute top-0 right-0 w-72 h-72 bg-yellow-400 opacity-5 rounded-full blur-3xl"></div>
        <div className="absolute bottom-0 left-0 w-96 h-96 bg-blue-400 opacity-5 rounded-full blur-3xl"></div>
      </div>

      <div className="mx-auto max-w-7xl px-4 py-12 sm:px-6">
        {/* Game Features */}
        <div className="grid md:grid-cols-3 gap-8 mb-20">
          <div className="bg-slate-800 p-8 rounded-lg border border-slate-700 hover:border-yellow-400 transition">
            <div className="text-4xl mb-4">🏰</div>
            <h3 className="text-xl font-bold mb-2">Explore the Manor</h3>
            <p className="text-slate-300">
              Navigate through 5 rooms filled with secrets, from the entrance to
              the cellar.
            </p>
          </div>

          <div className="bg-slate-800 p-8 rounded-lg border border-slate-700 hover:border-yellow-400 transition">
            <div className="text-4xl mb-4">🔍</div>
            <h3 className="text-xl font-bold mb-2">Find Clues</h3>
            <p className="text-slate-300">
              Collect evidence and investigate suspects. Each clue brings you
              closer to the truth.
            </p>
          </div>

          <div className="bg-slate-800 p-8 rounded-lg border border-slate-700 hover:border-yellow-400 transition">
            <div className="text-4xl mb-4">🎮</div>
            <h3 className="text-xl font-bold mb-2">Play Mini-Games</h3>
            <p className="text-slate-300">
              Unlock secrets with fun safe-cracking, match-3, riddles, memory
              games, and mazes.
            </p>
          </div>
        </div>

        {/* Game Stats */}
        <div className="bg-gradient-to-r from-slate-800 to-slate-700 p-8 rounded-lg mb-20 border border-slate-600">
          <h2 className="text-3xl font-bold mb-6">Game Highlights</h2>
          <div className="grid md:grid-cols-4 gap-6">
            <div className="text-center">
              <div className="text-4xl font-bold text-yellow-400">5</div>
              <p className="text-slate-300">Unique Rooms</p>
            </div>
            <div className="text-center">
              <div className="text-4xl font-bold text-yellow-400">5</div>
              <p className="text-slate-300">Mini-Games</p>
            </div>
            <div className="text-center">
              <div className="text-4xl font-bold text-yellow-400">5</div>
              <p className="text-slate-300">Clues to Find</p>
            </div>
            <div className="text-center">
              <div className="text-4xl font-bold text-yellow-400">∞</div>
              <p className="text-slate-300">Endless Mystery</p>
            </div>
          </div>
        </div>

        {/* Leaderboard */}
        <div className="bg-slate-800 p-8 rounded-lg border border-slate-700">
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-3xl font-bold">🏆 Leaderboard</h2>
            <a href="/game" className="text-yellow-400 hover:text-yellow-300">
              View All →
            </a>
          </div>

          {leaderboard && leaderboard.length > 0 ? (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="border-b border-slate-600">
                  <tr className="text-slate-400 text-sm">
                    <th className="text-left py-2">Rank</th>
                    <th className="text-left py-2">Player</th>
                    <th className="text-right py-2">Score</th>
                    <th className="text-right py-2">Time</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-700">
                  {leaderboard.slice(0, 10).map((entry: any, idx: number) => (
                    <tr
                      key={idx}
                      className="hover:bg-slate-700 transition text-sm"
                    >
                      <td className="py-3 font-bold">
                        {entry.rank_position === 1 && "🥇"}
                        {entry.rank_position === 2 && "🥈"}
                        {entry.rank_position === 3 && "🥉"}
                        {entry.rank_position > 3 && `#${entry.rank_position}`}
                      </td>
                      <td className="py-3 font-semibold">{entry.name}</td>
                      <td className="py-3 text-right text-yellow-400 font-bold">
                        {entry.total_score}
                      </td>
                      <td className="py-3 text-right text-slate-300">
                        {entry.time_spent_seconds
                          ? `${Math.floor(entry.time_spent_seconds / 60)}m`
                          : "-"}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <p className="text-slate-400 text-center py-8">
              No games completed yet. Be the first!
            </p>
          )}
        </div>

        {/* How to Play */}
        <div className="mt-20 bg-slate-800 p-8 rounded-lg border border-slate-700">
          <h2 className="text-3xl font-bold mb-6">How to Play</h2>
          <div className="grid md:grid-cols-2 gap-8">
            <div>
              <h3 className="text-lg font-bold text-yellow-400 mb-2">
                Game Flow
              </h3>
              <ul className="text-slate-300 space-y-2">
                <li>🚪 Start at the Entrance and explore each room</li>
                <li>🎮 Play a mini-game in each room to collect clues</li>
                <li>📋 Gather all 5 clues pointing to the killer</li>
                <li>🚨 Make your accusation and reveal the truth!</li>
              </ul>
            </div>
            <div>
              <h3 className="text-lg font-bold text-yellow-400 mb-2">
                Mini-Games
              </h3>
              <ul className="text-slate-300 space-y-2">
                <li>🔐 Safe-Cracker: Time your dial perfectly</li>
                <li>💎 Match-3: Match patterns to solve puzzles</li>
                <li>🧩 Riddles: Answer logic questions</li>
                <li>🧠 Memory: Find all matching pairs</li>
                <li>🧭 Maze: Navigate to the exit</li>
              </ul>
            </div>
          </div>
        </div>
      </div>

      {/* Footer */}
      <div className="border-t border-slate-700 mt-20 py-8 text-center text-slate-400">
        <p>Mystery Manor - Solve the murder. Claim the glory.</p>
      </div>
    </div>
  );
}
