"use client";

import { useState, useEffect, useRef } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";

// SAFE CRACKER GAME: Stop the dial in the green zone (REPLACES PLATFORMER)
function SafeCrackerGame({ onSuccess }: { onSuccess: () => void }) {
  const [angle, setAngle] = useState(0);
  const [speed, setSpeed] = useState(2.5);
  const [hits, setHits] = useState(0);
  const [message, setMessage] = useState("Press SPACE to stop the dial");
  const [isComplete, setIsComplete] = useState(false);
  const rafRef = useRef<number | null>(null);
  const targetRef = useRef({ start: 45, end: 95 });

  // Animation loop
  useEffect(() => {
    if (isComplete) return;

    const tick = () => {
      setAngle((a) => (a + speed) % 360);
      rafRef.current = requestAnimationFrame(tick);
    };
    rafRef.current = requestAnimationFrame(tick);
    return () => {
      if (rafRef.current) cancelAnimationFrame(rafRef.current);
    };
  }, [speed, isComplete]);

  // Keyboard handler
  useEffect(() => {
    if (isComplete) return;

    const onKey = (e: KeyboardEvent) => {
      if (e.code === "Space" || e.key === " ") {
        e.preventDefault();
        const { start, end } = targetRef.current;
        const ok = angle >= start && angle <= end;

        if (ok) {
          const nextHits = hits + 1;
          setHits(nextHits);
          
          if (nextHits >= 3) {
            setMessage("✓ Safe cracked! Collect the clue");
            setIsComplete(true);
          } else {
            setMessage(`Good! ${3 - nextHits} more to crack`);
            // Increase difficulty
            const newStart = (start + 40) % 360;
            const newEnd = (newStart + 40) % 360;
            targetRef.current = { start: newStart, end: newEnd };
            setSpeed((s) => Math.min(s + 0.7, 6));
          }
        } else {
          setMessage("❌ Missed! Try again");
          setSpeed((s) => Math.max(2, s - 0.3));
        }
      }
    };

    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [angle, hits, isComplete]);

  return (
    <div className="text-center">
      <h3 className="text-2xl font-bold mb-4">🔐 Safe Cracker</h3>
      <p className="text-slate-300 mb-6">{message}</p>

      <div className="inline-block bg-slate-900 p-6 rounded-lg border-2 border-slate-600 mb-6">
        <div className="relative w-64 h-64 bg-slate-800 rounded-full flex items-center justify-center border-4 border-slate-700">
          {/* Target zone (green arc) */}
          <svg className="absolute" width="256" height="256" viewBox="0 0 100 100">
            <circle cx="50" cy="50" r="40" fill="none" stroke="#1f2937" strokeWidth="10" />
            {(() => {
              const { start, end } = targetRef.current;
              const startRad = ((start - 90) * Math.PI) / 180;
              const endRad = ((end - 90) * Math.PI) / 180;
              const x1 = 50 + 40 * Math.cos(startRad);
              const y1 = 50 + 40 * Math.sin(startRad);
              const x2 = 50 + 40 * Math.cos(endRad);
              const y2 = 50 + 40 * Math.sin(endRad);
              const largeArc = end - start > 180 ? 1 : 0;
              return (
                <path
                  d={`M ${x1} ${y1} A 40 40 0 ${largeArc} 1 ${x2} ${y2}`}
                  fill="none"
                  stroke="#22c55e"
                  strokeWidth="10"
                  strokeLinecap="round"
                />
              );
            })()}
          </svg>

          {/* Rotating needle */}
          <div
            className="absolute w-1 h-24 bg-red-500 origin-bottom"
            style={{
              transform: `rotate(${angle}deg)`,
              bottom: "50%",
              transition: "none",
            }}
          />

          {/* Center circle */}
          <div className="absolute w-6 h-6 bg-slate-300 rounded-full" />
        </div>

        <div className="mt-4">
          <p className="text-slate-300">Hits: {hits}/3</p>
        </div>
      </div>

      <button
        onClick={onSuccess}
        disabled={!isComplete}
        className="w-full bg-green-600 hover:bg-green-700 disabled:bg-gray-600 font-bold py-2 rounded transition"
      >
        Collect Clue
      </button>
    </div>
  );
}

// MAZE GAME: Navigate Through the Maze
function MazeGame({ onSuccess }: { onSuccess: () => void }) {
  const [playerPos, setPlayerPos] = useState({ x: 0, y: 0 });
  const [completed, setCompleted] = useState(false);

  const GRID_SIZE = 5;
  const CELL_SIZE = 60;
  const GOAL = { x: 4, y: 4 };

  const maze = [
    [0, 1, 0, 0, 0],
    [0, 1, 0, 1, 0],
    [0, 0, 0, 1, 0],
    [1, 1, 0, 1, 0],
    [0, 0, 0, 0, 0],
  ];

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      let newX = playerPos.x;
      let newY = playerPos.y;

      if (e.key === "ArrowUp" && playerPos.y > 0) newY--;
      if (e.key === "ArrowDown" && playerPos.y < GRID_SIZE - 1) newY++;
      if (e.key === "ArrowLeft" && playerPos.x > 0) newX--;
      if (e.key === "ArrowRight" && playerPos.x < GRID_SIZE - 1) newX++;

      if (maze[newY] && maze[newY][newX] === 0) {
        setPlayerPos({ x: newX, y: newY });

        if (newX === GOAL.x && newY === GOAL.y) {
          setCompleted(true);
        }
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [playerPos, GRID_SIZE, GOAL.x, GOAL.y, maze]);

  return (
    <div className="text-center">
      <h3 className="text-2xl font-bold mb-4">🧭 Escape the Maze</h3>
      <p className="text-slate-300 mb-6">
        Use arrow keys to navigate to the exit
      </p>

      <div className="inline-block mb-6 bg-slate-700 p-4 rounded">
        <div
          className="relative bg-slate-900 border-2 border-slate-600"
          style={{
            width: `${GRID_SIZE * CELL_SIZE}px`,
            height: `${GRID_SIZE * CELL_SIZE}px`,
          }}
        >
          {/* Walls */}
          {maze.map((row, y) =>
            row.map((cell, x) =>
              cell === 1 ? (
                <div
                  key={`wall-${x}-${y}`}
                  className="absolute bg-slate-600"
                  style={{
                    left: `${x * CELL_SIZE}px`,
                    top: `${y * CELL_SIZE}px`,
                    width: `${CELL_SIZE}px`,
                    height: `${CELL_SIZE}px`,
                  }}
                />
              ) : null
            )
          )}

          {/* Goal */}
          <div
            className="absolute flex items-center justify-center text-2xl"
            style={{
              left: `${GOAL.x * CELL_SIZE}px`,
              top: `${GOAL.y * CELL_SIZE}px`,
              width: `${CELL_SIZE}px`,
              height: `${CELL_SIZE}px`,
            }}
          >
            🚪
          </div>

          {/* Player */}
          <div
            className="absolute flex items-center justify-center text-2xl transition-all duration-150"
            style={{
              left: `${playerPos.x * CELL_SIZE + CELL_SIZE / 2 - 15}px`,
              top: `${playerPos.y * CELL_SIZE + CELL_SIZE / 2 - 15}px`,
              width: "30px",
              height: "30px",
            }}
          >
            🕵️
          </div>
        </div>
      </div>

      <p className="text-slate-300 mb-6">
        {completed ? "✓ Escaped!" : "Find the exit"}
      </p>

      <button
        onClick={onSuccess}
        disabled={!completed}
        className="w-full bg-green-600 hover:bg-green-700 disabled:bg-gray-600 font-bold py-2 rounded transition"
      >
        Collect Clue
      </button>
    </div>
  );
}

// WORD SCRAMBLE GAME: Unscramble the words
function WordScrambleGame({ onSuccess }: { onSuccess: () => void }) {
  const words = [
    { scrambled: "OOPSNI", correct: "POISON" },
    { scrambled: "LAIHBIR", correct: "ALIBI" },
    { scrambled: "RECIM", correct: "CRIME" },
  ];

  const [wordIndex, setWordIndex] = useState(0);
  const [userAnswer, setUserAnswer] = useState("");
  const [solved, setSolved] = useState(new Set<number>());
  const [feedback, setFeedback] = useState("");

  const currentWord = words[wordIndex];
  const isSolved = solved.size === words.length;

  const handleGuess = () => {
    if (userAnswer.toUpperCase() === currentWord.correct) {
      const newSolved = new Set(solved);
      newSolved.add(wordIndex);
      setSolved(newSolved);
      setUserAnswer("");

      if (newSolved.size === words.length) {
        setFeedback("✓ All solved! Collect the clue");
      } else {
        setFeedback("✓ Correct!");
        setTimeout(() => {
          setWordIndex((prev) => {
            let next = prev + 1;
            while (next < words.length && solved.has(next)) {
              next++;
            }
            return next;
          });
          setFeedback("");
        }, 600);
      }
    } else {
      setFeedback("✗ Try again");
      setUserAnswer("");
    }
  };

  return (
    <div className="text-center">
      <h3 className="text-2xl font-bold mb-4">🔤 Word Scramble</h3>
      <p className="text-slate-300 mb-6">
        Unscramble the words • {solved.size}/{words.length}
      </p>

      <div className="bg-slate-700 p-8 rounded mb-6">
        <p className="text-5xl font-bold tracking-widest mb-6 text-yellow-300">
          {currentWord.scrambled}
        </p>
        <input
          type="text"
          placeholder="Type the word"
          value={userAnswer}
          onChange={(e) => setUserAnswer(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && !isSolved && handleGuess()}
          className="w-full px-4 py-3 bg-slate-600 text-white rounded mb-4 focus:outline-none focus:ring-2 focus:ring-yellow-400 text-center text-lg"
          disabled={isSolved}
          autoFocus
        />
        <button
          onClick={handleGuess}
          disabled={isSolved || !userAnswer.trim()}
          className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-gray-600 font-bold py-2 rounded transition"
        >
          Check Answer
        </button>
      </div>

      <p
        className={`text-lg font-bold mb-6 ${
          feedback.includes("✓")
            ? "text-green-400"
            : feedback.includes("✗")
            ? "text-red-400"
            : "text-slate-300"
        }`}
      >
        {feedback}
      </p>

      <button
        onClick={onSuccess}
        disabled={!isSolved}
        className="w-full bg-green-600 hover:bg-green-700 disabled:bg-gray-600 font-bold py-2 rounded transition"
      >
        Collect Clue
      </button>
    </div>
  );
}

// RIDDLE GAME: Logic Puzzle
function RiddleGame({ onSuccess }: { onSuccess: () => void }) {
  const riddles = [
    {
      question: "I have a face and two hands, but no arms or legs. What am I?",
      options: ["A watch", "A painting", "A mirror", "A clock"],
      correct: 3,
    },
    {
      question:
        "I am taken from a mine and shut up in a wooden case, from which I am never released, yet I am used by almost everyone. What am I?",
      options: ["A diamond", "Pencil lead", "Gold", "Coal"],
      correct: 1,
    },
    {
      question: "What can travel around the world while staying in a corner?",
      options: ["An airplane", "A stamp", "A bird", "Wind"],
      correct: 1,
    },
  ];

  const [riddleIndex, setRiddleIndex] = useState(0);
  const [answered, setAnswered] = useState(new Set<number>());
  const riddle = riddles[riddleIndex];

  const handleAnswer = (idx: number) => {
    if (idx === riddle.correct) {
      setAnswered(new Set(answered).add(riddleIndex));
      if (riddleIndex < riddles.length - 1) {
        setRiddleIndex(riddleIndex + 1);
      }
    }
  };

  const isSolved = answered.size === riddles.length;

  return (
    <div className="text-center">
      <h3 className="text-2xl font-bold mb-4">🧩 Riddle Master</h3>
      <p className="text-slate-300 mb-6">
        {riddleIndex + 1}/{riddles.length}
      </p>

      <div className="bg-slate-700 p-6 rounded mb-6">
        <p className="text-lg mb-4">{riddle.question}</p>
      </div>

      <div className="space-y-2 mb-6">
        {riddle.options.map((option, i) => (
          <button
            key={i}
            onClick={() => handleAnswer(i)}
            disabled={answered.has(riddleIndex)}
            className="w-full p-3 bg-slate-600 hover:bg-slate-500 disabled:opacity-50 rounded font-bold transition"
          >
            {option}
          </button>
        ))}
      </div>

      <button
        onClick={onSuccess}
        disabled={!isSolved}
        className="w-full bg-green-600 hover:bg-green-700 disabled:bg-gray-600 font-bold py-2 rounded transition"
      >
        Collect Clue
      </button>
    </div>
  );
}

// MEMORY GAME: Find Matching Pairs
function MemoryGame({ onSuccess }: { onSuccess: () => void }) {
  const items = ["🔪", "💀", "🧪", "👤", "💰", "🔑"];
  const [cards] = useState([...items, ...items].sort(() => Math.random() - 0.5));
  const [flipped, setFlipped] = useState(new Set<number>());
  const [matched, setMatched] = useState(new Set<number>());
  const [lastTwo, setLastTwo] = useState<[number, number] | null>(null);

  const handleClick = (i: number) => {
    if (flipped.has(i) || matched.has(i) || lastTwo) return;

    const newFlipped = new Set(flipped);
    newFlipped.add(i);

    if (flipped.size === 1) {
      const firstIdx = Array.from(flipped)[0];
      if (cards[firstIdx] === cards[i]) {
        setMatched(new Set(matched).add(firstIdx).add(i));
        setFlipped(new Set());
      } else {
        setLastTwo([firstIdx, i]);
        setTimeout(() => {
          setFlipped(new Set());
          setLastTwo(null);
        }, 1000);
      }
    } else {
      setFlipped(newFlipped);
    }
  };

  const progress = matched.size / cards.length;

  return (
    <div className="text-center">
      <h3 className="text-2xl font-bold mb-4">🧠 Memory Match</h3>
      <p className="text-slate-300 mb-6">Find all matching pairs</p>

      <div className="bg-slate-700 p-4 rounded mb-6 inline-block">
        <div className="grid grid-cols-4 gap-2">
          {cards.map((card, i) => (
            <button
              key={i}
              onClick={() => handleClick(i)}
              className={`w-14 h-14 rounded font-bold text-2xl transition ${
                flipped.has(i) || matched.has(i)
                  ? "bg-blue-600"
                  : "bg-slate-600 hover:bg-slate-500"
              }`}
            >
              {flipped.has(i) || matched.has(i) ? card : "?"}
            </button>
          ))}
        </div>
      </div>

      <div className="w-full bg-slate-700 rounded-full h-2 mb-4">
        <div
          className="bg-green-500 h-full rounded-full transition"
          style={{ width: `${progress * 100}%` }}
        />
      </div>

      <button
        onClick={onSuccess}
        disabled={matched.size < cards.length}
        className="w-full bg-green-600 hover:bg-green-700 disabled:bg-gray-600 font-bold py-2 rounded transition"
      >
        Collect Clue
      </button>
    </div>
  );
}

// ROOM SELECTOR
function RoomSelector({
  onSelectRoom,
}: {
  onSelectRoom: (room: any) => void;
}) {
  const rooms = [
    {
      id: 1,
      name: "Entrance",
      icon: "🚪",
      game: "Safe-Cracker",
      color: "red",
      bg: "/images/rooms/entrance.jpg",
    },
    {
      id: 2,
      name: "Gallery",
      icon: "🖼️",
      game: "Match-3",
      color: "blue",
      bg: "/images/rooms/gallery.jpg",
    },
    {
      id: 3,
      name: "Library",
      icon: "📚",
      game: "Riddle",
      color: "orange",
      bg: "/images/rooms/library.jpg",
    },
    {
      id: 4,
      name: "Study",
      icon: "🖊️",
      game: "Memory",
      color: "purple",
      bg: "/images/rooms/study.jpg",
    },
    {
      id: 5,
      name: "Cellar",
      icon: "🧭",
      game: "Maze",
      color: "green",
      bg: "/images/rooms/cellar.jpg",
    },
  ];

  return (
    <div className="text-center min-h-screen bg-gradient-to-b from-slate-900 to-slate-800 p-4">
      <h2 className="text-3xl font-bold mb-2 text-yellow-400">
        Mystery Manor
      </h2>
      <p className="text-slate-200 mb-8">
        Explore rooms and play games to collect clues
      </p>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 max-w-5xl mx-auto">
        {rooms.map((room) => (
          <button
            key={room.id}
            onClick={() => onSelectRoom(room)}
            className="p-6 rounded-lg border-2 bg-slate-800 hover:scale-105 transition font-bold text-lg overflow-hidden relative group"
            style={{
              borderColor:
                room.color === "red"
                  ? "#ef4444"
                  : room.color === "blue"
                  ? "#3b82f6"
                  : room.color === "orange"
                  ? "#f97316"
                  : room.color === "purple"
                  ? "#a855f7"
                  : "#22c55e",
            }}
          >
            <div className="relative z-10">
              <div className="text-4xl mb-2">{room.icon}</div>
              <div>{room.name}</div>
              <div className="text-xs text-slate-300 mt-1">{room.game}</div>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}

// CLUE CARD DISPLAY
function ClueCard({ clue }: { clue: any }) {
  return (
    <div className="bg-gradient-to-r from-yellow-900 to-amber-900 p-4 rounded border-2 border-yellow-600">
      <p className="text-sm text-yellow-100">{clue.text}</p>
      <p className="text-xs text-yellow-300 mt-2">Category: {clue.category}</p>
    </div>
  );
}

// MAIN GAME COMPONENT
export default function GamePage() {
  const [gameState, setGameState] = useState("menu");
  const [playerName, setPlayerName] = useState("");
  const [playerId, setPlayerId] = useState<number | null>(null);
  const [sessionId, setSessionId] = useState<number | null>(null);
  const [currentRoom, setCurrentRoom] = useState<any>(null);
  const [clues, setClues] = useState<any[]>([]);
  const [completedRooms, setCompletedRooms] = useState(new Set<number>());
  const [endScore, setEndScore] = useState<number | null>(null);

  const ROOM_CLUES: Record<number, any> = {
    1: {
      text: "A fine powder was found in the tea pot - Rat Poison",
      category: "Evidence",
    },
    2: {
      text: "The butler admitted he was in the kitchen at 7 PM",
      category: "Witness",
    },
    3: {
      text: "Miss Catherine was desperate for money (overheard arguing)",
      category: "Motive",
    },
    4: {
      text: "A tea cup with lipstick marks belonged to Miss Catherine",
      category: "Evidence",
    },
    5: {
      text: "Miss Catherine poured Lord Blackwood's tea that evening",
      category: "Witness",
    },
  };

  const createPlayerMutation = useMutation({
    mutationFn: async (name: string) => {
      const res = await fetch("/api/game/player", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name, email: null }),
      });
      if (!res.ok) throw new Error("Failed to create player");
      return res.json();
    },
  });

  const createSessionMutation = useMutation({
    mutationFn: async ({ playerId, playerName }: any) => {
      const res = await fetch("/api/game/session", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ playerId, playerName }),
      });
      if (!res.ok) throw new Error("Failed to create session");
      return res.json();
    },
  });

  const endSessionMutation = useMutation({
    mutationFn: async ({ sessionId, accusedCharacterId }: any) => {
      const res = await fetch("/api/game/session", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ sessionId, accusedCharacterId }),
      });
      if (!res.ok) throw new Error("Failed to end session");
      return res.json();
    },
  });

  const handleStartGame = async () => {
    if (!playerName.trim()) return;

    try {
      const player = await createPlayerMutation.mutateAsync(playerName);
      setPlayerId(player.player_id);

      const newSession = await createSessionMutation.mutateAsync({
        playerId: player.player_id,
        playerName: player.name,
      });
      setSessionId(newSession.session_id);
      setGameState("rooms");
    } catch (error) {
      console.error("Error starting game:", error);
      alert("Failed to start game");
    }
  };

  const handleRoomStart = (room: any) => {
    setCurrentRoom(room);
    setGameState("playing");
  };

  const handleGameComplete = () => {
    const clue = ROOM_CLUES[currentRoom.id];
    setClues([...clues, clue]);
    setCompletedRooms(new Set(completedRooms).add(currentRoom.id));
    setGameState("rooms");
  };

  const handleAccuse = async (suspectId: number) => {
    try {
      const result = await endSessionMutation.mutateAsync({
        sessionId,
        accusedCharacterId: suspectId,
      });
      setEndScore(result.final_score);
      setGameState("results");
    } catch (error) {
      console.error("Error ending session:", error);
      alert("Failed to submit accusation");
    }
  };

  if (gameState === "menu") {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-black flex items-center justify-center p-4">
        <div className="backdrop-blur-md bg-black/60 p-8 rounded-lg shadow-2xl w-full max-w-md">
          <h1 className="text-5xl font-bold text-yellow-400 mb-2">
            🕵️ Mystery Manor
          </h1>
          <p className="text-slate-300 mb-2 text-lg">Lord Blackwood is Dead</p>
          <p className="text-slate-400 mb-6">
            Explore the manor. Play mini-games. Collect clues. Find the killer.
          </p>

          <input
            type="text"
            placeholder="Enter your name"
            value={playerName}
            onChange={(e) => setPlayerName(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && handleStartGame()}
            className="w-full px-4 py-2 bg-slate-700 text-white rounded mb-4 focus:outline-none focus:ring-2 focus:ring-yellow-400"
          />

          <button
            onClick={handleStartGame}
            disabled={createPlayerMutation.isPending || !playerName.trim()}
            className="w-full bg-yellow-500 hover:bg-yellow-600 disabled:bg-gray-400 text-black font-bold py-3 rounded transition"
          >
            {createPlayerMutation.isPending
              ? "Starting..."
              : "Start Investigation"}
          </button>
        </div>
      </div>
    );
  }

  if (gameState === "rooms") {
    return (
      <div className="min-h-screen bg-gradient-to-b from-slate-900 to-slate-800 text-white p-4">
        <div className="max-w-4xl mx-auto">
          <div className="mb-8">
            <h1 className="text-3xl font-bold text-yellow-400 mb-2">
              🕵️ {playerName}&apos;s Investigation
            </h1>
            <p className="text-slate-300">Clues collected: {clues.length}/5</p>
          </div>

          <RoomSelector onSelectRoom={handleRoomStart} />

          {clues.length > 0 && (
            <div className="mt-12">
              <h2 className="text-2xl font-bold mb-4">📋 Your Clues</h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {clues.map((clue, i) => (
                  <ClueCard key={i} clue={clue} />
                ))}
              </div>

              {clues.length === 5 && (
                <button
                  onClick={() => setGameState("accusation")}
                  className="mt-6 w-full bg-red-600 hover:bg-red-700 text-white font-bold py-4 rounded-lg text-lg"
                >
                  🚨 Make Accusation
                </button>
              )}
            </div>
          )}
        </div>
      </div>
    );
  }

  if (gameState === "playing" && currentRoom) {
    const gameComponents: Record<number, any> = {
      1: SafeCrackerGame,
      2: WordScrambleGame,
      3: RiddleGame,
      4: MemoryGame,
      5: MazeGame,
    };

    const GameComponent = gameComponents[currentRoom.id];

    return (
      <div className="min-h-screen bg-gradient-to-b from-slate-900 to-slate-800 text-white p-4">
        <div className="max-w-2xl mx-auto">
          <div className="mb-6 flex justify-between items-center">
            <div>
              <h2 className="text-2xl font-bold">
                {currentRoom.icon} {currentRoom.name}
              </h2>
              <p className="text-slate-200">Playing: {currentRoom.game}</p>
            </div>
            <button
              onClick={() => setGameState("rooms")}
              className="px-4 py-2 bg-slate-700 hover:bg-slate-600 rounded"
            >
              Back
            </button>
          </div>

          <div className="bg-slate-800 p-8 rounded-lg border border-slate-700">
            <GameComponent onSuccess={handleGameComplete} />
          </div>
        </div>
      </div>
    );
  }

  if (gameState === "accusation") {
    return (
      <div className="min-h-screen bg-gradient-to-b from-slate-900 to-slate-800 text-white p-4 flex items-center justify-center">
        <div className="max-w-2xl mx-auto bg-slate-800 p-8 rounded-lg border border-slate-700">
          <h2 className="text-3xl font-bold mb-6">📋 Review the Evidence</h2>

          <div className="grid gap-4 mb-8">
            {clues.map((clue, i) => (
              <div
                key={i}
                className="bg-gradient-to-r from-yellow-900 to-amber-900 p-4 rounded border-2 border-yellow-600"
              >
                <p className="text-sm">{clue.text}</p>
                <p className="text-xs text-yellow-300 mt-1">{clue.category}</p>
              </div>
            ))}
          </div>

          <p className="text-lg mb-6 font-bold">Who is the killer?</p>
          <div className="grid grid-cols-2 gap-4">
            {[
              { id: 1, name: "Miss Catherine" },
              { id: 2, name: "Dr. Whitmore" },
              { id: 3, name: "Mr. Cornelius" },
              { id: 4, name: "Lady Margaret" },
            ].map((suspect) => (
              <button
                key={suspect.id}
                onClick={() => handleAccuse(suspect.id)}
                disabled={endSessionMutation.isPending}
                className="p-4 bg-slate-700 hover:bg-slate-600 disabled:opacity-50 rounded font-bold transition"
              >
                {suspect.name}
              </button>
            ))}
          </div>
        </div>
      </div>
    );
  }

  if (gameState === "results") {
    const isCorrect = endScore && endScore > 0;
    return (
      <div className="min-h-screen bg-gradient-to-b from-slate-900 to-slate-800 text-white p-4 flex items-center justify-center">
        <div className="max-w-2xl mx-auto bg-slate-800 p-8 rounded-lg border border-slate-700 text-center">
          <h2 className="text-4xl font-bold mb-4">
            {isCorrect ? "✓ CORRECT!" : "✗ WRONG!"}
          </h2>
          <p className="text-2xl text-yellow-400 mb-6">Score: {endScore}</p>
          <p className="text-slate-300 mb-8">
            {isCorrect
              ? "Miss Catherine poisoned Lord Blackwood for his inheritance!"
              : "That's not the killer. Better luck next time!"}
          </p>
          <a
            href="/game"
            className="inline-block bg-yellow-500 hover:bg-yellow-600 text-black font-bold px-6 py-3 rounded"
          >
            Play Again
          </a>
        </div>
      </div>
    );
  }

  return null;
}
