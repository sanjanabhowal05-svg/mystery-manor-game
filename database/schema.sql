

-- MySQL 8.0+ DDL (InnoDB, utf8mb4)
-- Order: core tables -> relations -> views -> routines -> triggers -> extra tables

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

-- Routines
DELIMITER $$

CREATE FUNCTION calculate_session_score(p_session_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE v_score INT DEFAULT 0;
  DECLARE v_time_bonus INT DEFAULT 0;
  DECLARE v_puzzle_score INT DEFAULT 0;
  DECLARE v_player_id INT DEFAULT NULL;

  SELECT COALESCE(SUM(p.points), 0)
    INTO v_puzzle_score
  FROM puzzle p
  WHERE p.puzzle_id IN (
    SELECT pa.puzzle_id
    FROM puzzle_attempt pa
    WHERE pa.session_id = p_session_id AND pa.correct = 1
  );

  SELECT COALESCE(gs.time_spent_seconds, 0), gs.player_id
    INTO v_time_bonus, v_player_id
  FROM game_session gs
  WHERE gs.session_id = p_session_id;

  IF v_time_bonus < 1800 THEN
    SET v_time_bonus = 100;
  ELSE
    SET v_time_bonus = GREATEST(0, 100 - FLOOR((v_time_bonus - 1800) / 60));
  END IF;

  SELECT COALESCE(COUNT(*) * 5, 0)
    INTO v_score
  FROM player_inventory
  WHERE player_id = v_player_id;

  RETURN v_puzzle_score + v_time_bonus + v_score;
END$$

CREATE PROCEDURE end_game_session(IN p_session_id INT, IN p_accused_character_id INT)
BEGIN
  DECLARE v_is_correct BOOLEAN DEFAULT 0;
  DECLARE v_final_score INT DEFAULT 0;
  DECLARE v_player_id INT DEFAULT NULL;

  SELECT gc.is_killer INTO v_is_correct
  FROM game_character gc
  WHERE gc.character_id = p_accused_character_id;

  SELECT gs.player_id, calculate_session_score(p_session_id)
    INTO v_player_id, v_final_score
  FROM game_session gs
  WHERE gs.session_id = p_session_id;

  UPDATE game_session
  SET
    status = 'completed',
    ended_at = CURRENT_TIMESTAMP,
    total_score = v_final_score,
    accused_character_id = p_accused_character_id,
    is_correct_accusation = v_is_correct
  WHERE session_id = p_session_id;

  UPDATE player
  SET
    total_score = total_score + v_final_score,
    games_played = games_played + 1,
    last_played = CURRENT_TIMESTAMP
  WHERE player_id = v_player_id;

  SELECT p_session_id AS session_id,
         v_final_score AS final_score,
         v_is_correct AS is_correct,
         CASE WHEN v_is_correct THEN 'Correct! You found the killer!' ELSE 'Wrong accusation!' END AS message;
END$$

DELIMITER ;

-- Triggers
DELIMITER $$

CREATE TRIGGER trg_increment_puzzles_solved
AFTER INSERT ON puzzle_attempt
FOR EACH ROW
BEGIN
  IF NEW.correct = 1 THEN
    UPDATE game_session
    SET puzzles_solved = puzzles_solved + 1
    WHERE session_id = NEW.session_id;
  END IF;
END$$

CREATE TRIGGER trg_update_player_last_played
AFTER INSERT ON game_session
FOR EACH ROW
BEGIN
  UPDATE player
  SET last_played = CURRENT_TIMESTAMP
  WHERE player_id = NEW.player_id;
END$$

DELIMITER ;

-- Five additional tables for game flow and narrative depth

CREATE TABLE scene_transition (
  transition_id INT AUTO_INCREMENT PRIMARY KEY,
  from_scene_id INT NOT NULL,
  to_scene_id INT NOT NULL,
  condition_type VARCHAR(50) DEFAULT 'none',   -- e.g., puzzle_solved, item_collected, accusation_made
  condition_value VARCHAR(100) NULL,           -- e.g., puzzle_id, item_id, character_id
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
  event_type VARCHAR(50) NOT NULL,     -- e.g., PUZZLE_SOLVED, ITEM_FOUND, TRANSITION_UNLOCKED
  event_details JSON NULL,             -- flexible metadata for frontend/analytics
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


INSERT INTO game_character (character_id, name, role, is_killer) VALUES
(1, 'Miss Catherine', 'Housemaid', 1),
(2, 'Dr. Whitmore', 'Family Doctor', 0),
(3, 'Mr. Cornelius', 'Lawyer', 0),
(4, 'Lady Margaret', 'Wife', 0)
ON DUPLICATE KEY UPDATE is_killer = VALUES(is_killer);
