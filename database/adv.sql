DELIMITER $$

CREATE PROCEDURE end_game_session(IN p_session_id INT, IN p_accused_character_id INT)
BEGIN
  DECLARE v_is_correct BOOLEAN DEFAULT 0;
  DECLARE v_final_score INT DEFAULT 0;
  DECLARE v_player_id INT DEFAULT NULL;

  SELECT gc.is_killer INTO v_is_correct
  FROM game_character gc
  WHERE gc.character_id = p_accused_character_id;

  SELECT gs.player_id, 0
    INTO v_player_id, v_final_score
  FROM game_session gs
  WHERE gs.session_id = p_session_id;

  UPDATE game_session
  SET
    status = 'completed',
    ended_at = CURRENT_TIMESTAMP,
    total_score = 100,
    accused_character_id = p_accused_character_id,
    is_correct_accusation = v_is_correct
  WHERE session_id = p_session_id;

  UPDATE player
  SET
    total_score = total_score + 100,
    games_played = games_played + 1,
    last_played = CURRENT_TIMESTAMP
  WHERE player_id = v_player_id;

  SELECT p_session_id AS session_id,
         100 AS final_score,
         v_is_correct AS is_correct,
         CASE WHEN v_is_correct THEN 'Correct! You found the killer!' ELSE 'Wrong accusation!' END AS message;
END$$

DELIMITER ;
