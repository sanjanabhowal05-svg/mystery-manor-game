-- MySQL 8.0+ DDL with SEED DATA
-- Mystery Manor Game Database

-- Core entities
CREATE TABLE player (
  player_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(150) UNIQUE,
  total_score INT DEFAULT 0,
  games_played INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_played TIMESTAMP NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE room (
  room_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  description TEXT,
  bg_color VARCHAR(7) DEFAULT '#333333',
  difficulty_level INT DEFAULT 1,
  position_x INT DEFAULT 0,
  position_y INT DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE scene (
  scene_id INT AUTO_INCREMENT PRIMARY KEY,
  room_id INT NULL,
  title VARCHAR(200),
  description TEXT,
  clue_text TEXT,
  is_critical BOOLEAN DEFAULT FALSE,
  CONSTRAINT fk_scene_room
    FOREIGN KEY (room_id) REFERENCES room(room_id)
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE game_character (
  character_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  role VARCHAR(120),
  room_id INT NULL,
  bio TEXT,
  suspicion_level INT DEFAULT 0,
  alibi TEXT,
  is_killer BOOLEAN DEFAULT FALSE,
  CONSTRAINT fk_character_room
    FOREIGN KEY (room_id) REFERENCES room(room_id)
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE inventory_item (
  item_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(200) NOT NULL,
  type VARCHAR(50),
  description TEXT,
  point_value INT DEFAULT 10,
  rarity VARCHAR(20) DEFAULT 'common'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE achievement (
  achievement_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  description TEXT,
  points INT DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE game_session (
  session_id INT AUTO_INCREMENT PRIMARY KEY,
  player_id INT NOT NULL,
  player_name VARCHAR(100),
  started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ended_at TIMESTAMP NULL,
  current_scene INT DEFAULT 1,
  hints_used INT DEFAULT 0,
  items_collected INT DEFAULT 0,
  puzzles_solved INT DEFAULT 0,
  total_score INT DEFAULT 0,
  time_spent_seconds INT DEFAULT 0,
  status VARCHAR(20) DEFAULT 'active',
  accused_character_id INT NULL,
  is_correct_accusation BOOLEAN DEFAULT FALSE,
  CONSTRAINT fk_session_player
    FOREIGN KEY (player_id) REFERENCES player(player_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_session_accused_character
    FOREIGN KEY (accused_character_id) REFERENCES game_character(character_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE puzzle (
  puzzle_id INT AUTO_INCREMENT PRIMARY KEY,
  scene_id INT,
  title VARCHAR(200),
  description TEXT,
  answer VARCHAR(255),
  hint_text TEXT,
  points INT DEFAULT 50,
  difficulty INT DEFAULT 1,
  CONSTRAINT fk_puzzle_scene
    FOREIGN KEY (scene_id) REFERENCES scene(scene_id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE puzzle_attempt (
  attempt_id INT AUTO_INCREMENT PRIMARY KEY,
  session_id INT,
  puzzle_id INT,
  answer VARCHAR(255),
  correct BOOLEAN,
  attempted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_attempt_puzzle
    FOREIGN KEY (puzzle_id) REFERENCES puzzle(puzzle_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_attempt_session
    FOREIGN KEY (session_id) REFERENCES game_session(session_id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE player_inventory (
  pi_id INT AUTO_INCREMENT PRIMARY KEY,
  player_id INT,
  item_id INT,
  qty INT DEFAULT 1,
  found_at_scene INT,
  found_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_player_item (player_id, item_id),
  CONSTRAINT fk_pi_player
    FOREIGN KEY (player_id) REFERENCES player(player_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_pi_item
    FOREIGN KEY (item_id) REFERENCES inventory_item(item_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_pi_scene
    FOREIGN KEY (found_at_scene) REFERENCES scene(scene_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE player_achievement (
  pa_id INT AUTO_INCREMENT PRIMARY KEY,
  player_id INT,
  achievement_id INT,
  unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_player_achievement (player_id, achievement_id),
  CONSTRAINT fk_pa_player
    FOREIGN KEY (player_id) REFERENCES player(player_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_pa_achievement
    FOREIGN KEY (achievement_id) REFERENCES achievement(achievement_id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE scene_transition (
  transition_id INT AUTO_INCREMENT PRIMARY KEY,
  from_scene_id INT NOT NULL,
  to_scene_id INT NOT NULL,
  condition_type VARCHAR(50) DEFAULT 'none',
  condition_value VARCHAR(100) NULL,
  is_locked BOOLEAN DEFAULT FALSE,
  CONSTRAINT fk_trans_from_scene
    FOREIGN KEY (from_scene_id) REFERENCES scene(scene_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_trans_to_scene
    FOREIGN KEY (to_scene_id) REFERENCES scene(scene_id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE room_connection (
  connection_id INT AUTO_INCREMENT PRIMARY KEY,
  from_room_id INT NOT NULL,
  to_room_id INT NOT NULL,
  bidirectional BOOLEAN DEFAULT TRUE,
  CONSTRAINT fk_conn_from_room
    FOREIGN KEY (from_room_id) REFERENCES room(room_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_conn_to_room
    FOREIGN KEY (to_room_id) REFERENCES room(room_id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE evidence (
  evidence_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(200) NOT NULL,
  description TEXT,
  type VARCHAR(50),
  points INT DEFAULT 20,
  found_at_scene INT NULL,
  implicates_character_id INT NULL,
  CONSTRAINT fk_evidence_scene
    FOREIGN KEY (found_at_scene) REFERENCES scene(scene_id)
    ON DELETE SET NULL,
  CONSTRAINT fk_evidence_character
    FOREIGN KEY (implicates_character_id) REFERENCES game_character(character_id)
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE session_event (
  event_id INT AUTO_INCREMENT PRIMARY KEY,
  session_id INT NOT NULL,
  event_type VARCHAR(50) NOT NULL,
  event_details JSON NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_event_session
    FOREIGN KEY (session_id) REFERENCES game_session(session_id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE dialogue_line (
  dialogue_id INT AUTO_INCREMENT PRIMARY KEY,
  character_id INT NOT NULL,
  scene_id INT NULL,
  line_text TEXT NOT NULL,
  emotion VARCHAR(30),
  order_index INT DEFAULT 0,
  unlock_condition VARCHAR(100),
  CONSTRAINT fk_dialogue_character
    FOREIGN KEY (character_id) REFERENCES game_character(character_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_dialogue_scene
    FOREIGN KEY (scene_id) REFERENCES scene(scene_id)
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Views
CREATE VIEW player_stats_view AS
SELECT
  p.player_id,
  p.name,
  COUNT(gs.session_id) AS total_games,
  AVG(gs.total_score) AS avg_score,
  MAX(gs.total_score) AS best_score,
  COUNT(DISTINCT pa.achievement_id) AS total_achievements
FROM player p
LEFT JOIN game_session gs ON p.player_id = gs.player_id
LEFT JOIN player_achievement pa ON p.player_id = pa.player_id
GROUP BY p.player_id, p.name;

CREATE VIEW puzzle_difficulty_view AS
SELECT
  p.puzzle_id,
  p.title,
  p.difficulty,
  COUNT(pa.attempt_id) AS total_attempts,
  SUM(CASE WHEN pa.correct = 1 THEN 1 ELSE 0 END) AS correct_attempts,
  ROUND(
    (100.0 * SUM(CASE WHEN pa.correct = 1 THEN 1 ELSE 0 END)) /
    NULLIF(COUNT(pa.attempt_id), 0), 2
  ) AS success_rate
FROM puzzle p
LEFT JOIN puzzle_attempt pa ON p.puzzle_id = pa.puzzle_id
GROUP BY p.puzzle_id, p.title, p.difficulty;

CREATE VIEW leaderboard_view AS
SELECT
  p.player_id,
  p.name,
  gs.session_id,
  gs.total_score,
  gs.time_spent_seconds,
  gs.ended_at,
  RANK() OVER (ORDER BY gs.total_score DESC, gs.time_spent_seconds ASC) AS rank_position
FROM game_session gs
JOIN player p ON gs.player_id = p.player_id
WHERE gs.status = 'completed' AND gs.ended_at IS NOT NULL;

-- ============================================
-- SEED DATA
-- ============================================

-- Players (works with game)

-- Rooms (5 entries)
INSERT INTO room (name, description, bg_color, difficulty_level, position_x, position_y) VALUES
('Entrance Hall', 'Grand entrance with marble floors', '#2d3748', 1, 0, 0),
('Art Gallery', 'Walls adorned with priceless paintings', '#1a365d', 2, 100, 0),
('Library', 'Floor-to-ceiling bookshelves', '#744210', 3, 0, 100),
('Study', 'Lord Blackwood''s private workspace', '#4c1d95', 4, 100, 100),
('Wine Cellar', 'Dark basement with ancient barrels', '#1a202c', 5, 50, 200);

-- Scenes (10 entries)
INSERT INTO scene (room_id, title, description, clue_text, is_critical) VALUES
(1, 'Main Entrance', 'You enter the grand manor', 'A tea cup sits on the entrance table', TRUE),
(1, 'Reception Desk', 'An ornate wooden desk', 'Guest book shows recent visitors', FALSE),
(2, 'Portrait Wall', 'Family portraits line the walls', 'Lord Blackwood''s portrait has been defaced', TRUE),
(2, 'Display Case', 'Antique items on display', 'A key is hidden behind a vase', FALSE),
(3, 'Reading Nook', 'Cozy corner with armchairs', 'A diary entry dated yesterday', TRUE),
(3, 'Ancient Texts', 'Rare book collection', 'A book about poisons is missing', FALSE),
(4, 'Desk Area', 'Mahogany desk with papers', 'Financial documents show debt', TRUE),
(4, 'Safe', 'Hidden wall safe', 'Will document names Miss Catherine as beneficiary', TRUE),
(5, 'Wine Racks', 'Dusty bottles everywhere', 'Empty rat poison bottle hidden behind wine', TRUE),
(5, 'Storage Area', 'Old furniture and crates', 'Footprints lead to the poison', FALSE);

-- Game Characters (10 entries - 4 suspects + 6 witnesses)


-- Inventory Items (10 entries)
INSERT INTO inventory_item (name, type, description, point_value, rarity) VALUES
('Tea Cup', 'Evidence', 'Porcelain cup with lipstick marks', 20, 'common'),
('Poison Bottle', 'Evidence', 'Empty rat poison container', 50, 'rare'),
('Diary', 'Clue', 'Lord Blackwood''s personal diary', 30, 'uncommon'),
('Will Document', 'Evidence', 'Legal document naming heir', 40, 'rare'),
('Key Ring', 'Item', 'Set of manor keys', 10, 'common'),
('Financial Papers', 'Clue', 'Documents showing debt', 25, 'uncommon'),
('Torn Letter', 'Clue', 'Fragment of threatening letter', 35, 'uncommon'),
('Magnifying Glass', 'Tool', 'Helps examine evidence', 15, 'common'),
('Fingerprint Kit', 'Tool', 'Dusting powder and brush', 20, 'uncommon'),
('Photo Album', 'Clue', 'Family photographs', 10, 'common');

-- Achievements (10 entries)
INSERT INTO achievement (name, description, points) VALUES
('First Case', 'Complete your first investigation', 100),
('Perfect Detective', 'Solve case without hints', 200),
('Speed Runner', 'Complete in under 5 minutes', 300),
('Eagle Eye', 'Find all hidden clues', 150),
('Master Sleuth', 'Solve 10 cases', 500),
('Puzzle Master', 'Solve all puzzles correctly', 250),
('Evidence Collector', 'Collect all items', 150),
('Quick Thinker', 'Solve 3 puzzles in a row', 100),
('Manor Explorer', 'Visit all rooms', 50),
('Champion Detective', 'Top 10 on leaderboard', 400);

-- Game Sessions (10 entries)
-- with the game 

-- Puzzles (10 entries)
INSERT INTO puzzle (scene_id, title, description, answer, hint_text, points, difficulty) VALUES
(1, 'Tea Cup Mystery', 'Whose lipstick is on the cup?', 'Catherine', 'Check the color', 50, 1),
(3, 'Portrait Riddle', 'Why was the portrait defaced?', 'Revenge', 'Look at the damage pattern', 60, 2),
(5, 'Diary Code', 'Decode the hidden message', 'POISON', 'Use the first letter of each line', 70, 3),
(7, 'Financial Puzzle', 'Calculate the debt amount', '50000', 'Add all the bills', 50, 2),
(9, 'Poison Trace', 'Where did the poison come from?', 'Cellar', 'Follow the footprints', 80, 3),
(2, 'Guest Book', 'Who visited last?', 'Catherine', 'Check the last entry', 40, 1),
(4, 'Key Match', 'Which key opens the safe?', 'Golden', 'Try each one', 30, 1),
(6, 'Book Cipher', 'What page is marked?', '42', 'Look for the bookmark', 50, 2),
(8, 'Will Reading', 'Who inherits?', 'Catherine', 'Read the document', 60, 2),
(10, 'Footprint Analysis', 'Shoe size of the culprit?', '7', 'Measure carefully', 40, 1);

-- Puzzle Attempts (10 entries)
INSERT INTO puzzle_attempt (session_id, puzzle_id, answer, correct, attempted_at) VALUES
(1, 1, 'Catherine', 1, DATE_SUB(NOW(), INTERVAL 55 MINUTE)),
(1, 3, 'Revenge', 1, DATE_SUB(NOW(), INTERVAL 50 MINUTE)),
(2, 1, 'Margaret', 0, DATE_SUB(NOW(), INTERVAL 1 HOUR 50 MINUTE)),
(2, 1, 'Catherine', 1, DATE_SUB(NOW(), INTERVAL 1 HOUR 48 MINUTE)),
(3, 5, 'MURDER', 0, DATE_SUB(NOW(), INTERVAL 2 HOUR 35 MINUTE)),
(3, 5, 'POISON', 1, DATE_SUB(NOW(), INTERVAL 2 HOUR 30 MINUTE)),
(4, 2, 'Anger', 0, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(5, 7, 'Silver', 0, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(6, 9, 'Kitchen', 0, DATE_SUB(NOW(), INTERVAL 3 DAY)),
(7, 1, 'Catherine', 1, DATE_SUB(NOW(), INTERVAL 4 DAY));

-- Room Connections (10 entries)
INSERT INTO room_connection (from_room_id, to_room_id, bidirectional) VALUES
(1, 2, 1),
(1, 3, 1),
(2, 4, 1),
(3, 4, 1),
(1, 5, 1),
(2, 5, 0),
(3, 5, 0),
(4, 5, 1),
(2, 3, 1),
(4, 1, 1);

-- Evidence (10 entries)
INSERT INTO evidence (name, description, type, points, found_at_scene, implicates_character_id) VALUES
('Lipstick-stained Cup', 'Tea cup with red lipstick', 'Physical', 30, 1, 1),
('Poison Bottle', 'Empty rat poison container', 'Physical', 50, 9, 1),
('Threatening Letter', 'Anonymous threat to Lord Blackwood', 'Document', 40, 7, 1),
('Will Document', 'Names Miss Catherine as heir', 'Document', 45, 8, 1),
('Diary Entry', 'Lord Blackwood feared for his life', 'Document', 35, 5, NULL),
('Fingerprints', 'Found on poison bottle', 'Forensic', 50, 9, 1),
('Witness Statement', 'Butler saw Catherine in kitchen', 'Testimony', 30, 1, 1),
('Financial Records', 'Catherine had debts', 'Document', 25, 7, 1),
('Shoe Print', 'Size 7 female shoe', 'Physical', 30, 10, 1),
('Tea Leaves', 'Poisoned tea remnants', 'Physical', 40, 1, 1);

-- Session Events (10 entries)  
INSERT INTO session_event (session_id, event_type, event_details) VALUES
(1, 'PUZZLE_SOLVED', '{"puzzle_id": 1, "time": 120}'),
(1, 'ITEM_FOUND', '{"item_id": 1, "scene_id": 1}'),
(2, 'PUZZLE_SOLVED', '{"puzzle_id": 2, "time": 180}'),
(3, 'TRANSITION_UNLOCKED', '{"from_scene": 1, "to_scene": 2}'),
(4, 'HINT_USED', '{"puzzle_id": 3, "hints_remaining": 2}'),
(5, 'PUZZLE_SOLVED', '{"puzzle_id": 5, "time": 240}'),
(6, 'ITEM_FOUND', '{"item_id": 2, "scene_id": 9}'),
(7, 'ACCUSATION_MADE', '{"character_id": 1, "correct": true}'),
(8, 'PUZZLE_FAILED', '{"puzzle_id": 4, "attempts": 3}'),
(9, 'GAME_COMPLETED', '{"total_score": 450, "time": 1100}');

-- Dialogue Lines (10 entries)
INSERT INTO dialogue_line (character_id, scene_id, line_text, emotion, order_index) VALUES
(1, 1, 'I served Lord Blackwood his tea at exactly 7 PM.', 'nervous', 1),
(1, 8, 'I had no idea I was named in the will!', 'defensive', 2),
(2, 3, 'Lord Blackwood was in perfect health last week.', 'concerned', 1),
(3, 4, 'The will was changed just last month.', 'serious', 1),
(4, 2, 'I was shopping in London all day.', 'anxious', 1),
(5, 1, 'Miss Catherine seemed nervous that evening.', 'suspicious', 1),
(6, 5, 'I prepared the tea as usual, nothing strange.', 'worried', 1),
(7, NULL, 'I saw someone near the cellar around 6 PM.', 'helpful', 1),
(8, 2, 'Miss Catherine asked me to leave early.', 'uncertain', 1),
(9, NULL, 'Lord Blackwood seemed troubled lately.', 'sad', 1);

-- Scene Transitions (10 entries)
INSERT INTO scene_transition (from_scene_id, to_scene_id, condition_type, condition_value, is_locked) VALUES
(1, 2, 'none', NULL, 0),
(2, 3, 'puzzle_solved', '1', 0),
(3, 5, 'none', NULL, 0),
(5, 7, 'item_collected', '3', 0),
(7, 8, 'puzzle_solved', '7', 1),
(8, 9, 'item_collected', '4', 1),
(4, 6, 'none', NULL, 0),
(6, 10, 'puzzle_solved', '6', 0),
(9, 10, 'none', NULL, 0),
(10, 1, 'none', NULL, 0);

-- Player Inventory (10 entries)
INSERT INTO player_inventory (player_id, item_id, qty, found_at_scene) VALUES
(1, 1, 1, 1),
(1, 2, 1, 9),
(1, 3, 1, 5),
(2, 1, 1, 1),
(2, 4, 1, 8),
(3, 2, 1, 9),
(3, 7, 1, 7),
(4, 8, 1, NULL),
(5, 1, 1, 1),
(5, 9, 1, NULL);

-- Player Achievements (10 entries)
INSERT INTO player_achievement (player_id, achievement_id) VALUES
(1, 1),
(1, 9),
(2, 1),
(2, 9),
(3, 1),
(4, 1),
(5, 1),
(5, 2),
(7, 1),
(7, 3);


