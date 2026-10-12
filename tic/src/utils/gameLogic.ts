import { GridSize, Player, CellValue, WinningLine, AIDifficulty, GRID_CONFIGS } from '../types/game';

/**
 * Checks for a win in a grid of size N with winCount K.
 */
export function checkWin(
  board: CellValue[],
  size: GridSize
): { winner: Player; line: WinningLine } | null {
  const k = GRID_CONFIGS[size].winCount;

  const getCell = (r: number, c: number): CellValue => {
    if (r < 0 || r >= size || c < 0 || c >= size) return null;
    return board[r * size + c];
  };

  const getIndex = (r: number, c: number) => r * size + c;

  // Directions: [deltaRow, deltaCol, directionName]
  const directions: Array<[number, number, WinningLine['direction']]> = [
    [0, 1, 'horizontal'],
    [1, 0, 'vertical'],
    [1, 1, 'diagonal-main'],
    [1, -1, 'diagonal-anti'],
  ];

  for (let r = 0; r < size; r++) {
    for (let c = 0; c < size; c++) {
      const current = getCell(r, c);
      if (!current) continue;

      for (const [dr, dc, dir] of directions) {
        // Check if K-length line fits in grid
        const endR = r + dr * (k - 1);
        const endC = c + dc * (k - 1);

        if (endR < 0 || endR >= size || endC < 0 || endC >= size) {
          continue;
        }

        let isLine = true;
        const cells: number[] = [getIndex(r, c)];

        for (let step = 1; step < k; step++) {
          const nextR = r + dr * step;
          const nextC = c + dc * step;
          if (getCell(nextR, nextC) !== current) {
            isLine = false;
            break;
          }
          cells.push(getIndex(nextR, nextC));
        }

        if (isLine) {
          return {
            winner: current,
            line: {
              startIndex: getIndex(r, c),
              endIndex: getIndex(endR, endC),
              cells,
              direction: dir,
            },
          };
        }
      }
    }
  }

  return null;
}

/**
 * Checks if the board is completely filled (draw).
 */
export function checkDraw(board: CellValue[]): boolean {
  return board.every((cell) => cell !== null);
}

/**
 * Minimax algorithm for 3x3 unbeatable AI.
 */
function getBest3x3Move(board: CellValue[], aiPlayer: Player): number {
  const humanPlayer: Player = aiPlayer === 'X' ? 'O' : 'X';

  function minimax(currentBoard: CellValue[], depth: number, isMaximizing: boolean): number {
    const winResult = checkWin(currentBoard, 3);
    if (winResult) {
      return winResult.winner === aiPlayer ? 10 - depth : depth - 10;
    }
    if (checkDraw(currentBoard)) {
      return 0;
    }

    if (isMaximizing) {
      let maxEval = -Infinity;
      for (let i = 0; i < 9; i++) {
        if (!currentBoard[i]) {
          currentBoard[i] = aiPlayer;
          const score = minimax(currentBoard, depth + 1, false);
          currentBoard[i] = null;
          maxEval = Math.max(maxEval, score);
        }
      }
      return maxEval;
    } else {
      let minEval = Infinity;
      for (let i = 0; i < 9; i++) {
        if (!currentBoard[i]) {
          currentBoard[i] = humanPlayer;
          const score = minimax(currentBoard, depth + 1, true);
          currentBoard[i] = null;
          minEval = Math.min(minEval, score);
        }
      }
      return minEval;
    }
  }

  let bestScore = -Infinity;
  let bestMove = -1;
  const boardCopy = [...board];

  // Try center first if empty
  if (!boardCopy[4]) {
    // High probability of taking center for realistic play
    if (Math.random() > 0.15) return 4;
  }

  const availableMoves: number[] = [];
  for (let i = 0; i < 9; i++) {
    if (!boardCopy[i]) availableMoves.push(i);
  }

  for (const move of availableMoves) {
    boardCopy[move] = aiPlayer;
    const score = minimax(boardCopy, 0, false);
    boardCopy[move] = null;

    if (score > bestScore) {
      bestScore = score;
      bestMove = move;
    }
  }

  return bestMove !== -1 ? bestMove : availableMoves[Math.floor(Math.random() * availableMoves.length)];
}

/**
 * Heuristic AI move selector for 6x6, 9x9, 11x11 boards.
 * Blazing fast, tactical threat detection, blocks opponent streaks, builds own streaks.
 */
function getHeuristicMove(
  board: CellValue[],
  size: GridSize,
  aiPlayer: Player,
  difficulty: AIDifficulty
): number {
  const humanPlayer: Player = aiPlayer === 'X' ? 'O' : 'X';
  const k = GRID_CONFIGS[size].winCount;

  const emptyIndices: number[] = [];
  board.forEach((val, idx) => {
    if (val === null) emptyIndices.push(idx);
  });

  if (emptyIndices.length === 0) return -1;

  // First move of the game on large boards: pick near the center
  const totalOccupied = board.filter((c) => c !== null).length;
  if (totalOccupied === 0) {
    const center = Math.floor(size / 2) * size + Math.floor(size / 2);
    return center;
  }

  // Easy mode: 45% random choice
  if (difficulty === 'easy' && Math.random() < 0.45) {
    return emptyIndices[Math.floor(Math.random() * emptyIndices.length)];
  }

  // Check 1: Can AI win immediately?
  for (const idx of emptyIndices) {
    board[idx] = aiPlayer;
    const win = checkWin(board, size);
    board[idx] = null;
    if (win) return idx;
  }

  // Check 2: Can human win next turn? Block it!
  if (difficulty !== 'easy' || Math.random() > 0.3) {
    for (const idx of emptyIndices) {
      board[idx] = humanPlayer;
      const win = checkWin(board, size);
      board[idx] = null;
      if (win) return idx;
    }
  }

  // Candidate evaluation score for each empty spot
  const scores = new Map<number, number>();

  // Only consider empty cells that have at least one piece within Manhattan distance 2
  const relevantMoves = emptyIndices.filter((idx) => {
    const r = Math.floor(idx / size);
    const c = idx % size;
    for (let dr = -2; dr <= 2; dr++) {
      for (let dc = -2; dc <= 2; dc++) {
        const nr = r + dr;
        const nc = c + dc;
        if (nr >= 0 && nr < size && nc >= 0 && nc < size) {
          if (board[nr * size + nc] !== null) return true;
        }
      }
    }
    return false;
  });

  const movesToEvaluate = relevantMoves.length > 0 ? relevantMoves : emptyIndices;

  const directions = [
    [0, 1], // horizontal
    [1, 0], // vertical
    [1, 1], // main diag
    [1, -1], // anti diag
  ];

  for (const move of movesToEvaluate) {
    let moveScore = 0;
    const r = Math.floor(move / size);
    const c = move % size;

    // Small bonus for being closer to center
    const centerDist = Math.abs(r - size / 2) + Math.abs(c - size / 2);
    moveScore += (size - centerDist) * 2;

    for (const [dr, dc] of directions) {
      // Evaluate windows of length K that include this cell
      for (let offset = -(k - 1); offset <= 0; offset++) {
        let aiCount = 0;
        let humanCount = 0;
        let validWindow = true;

        for (let step = 0; step < k; step++) {
          const checkR = r + (offset + step) * dr;
          const checkC = c + (offset + step) * dc;

          if (checkR < 0 || checkR >= size || checkC < 0 || checkC >= size) {
            validWindow = false;
            break;
          }

          if (checkR === r && checkC === c) {
            // This is the hypothetical move cell
            continue;
          }

          const cellVal = board[checkR * size + checkC];
          if (cellVal === aiPlayer) aiCount++;
          else if (cellVal === humanPlayer) humanCount++;
        }

        if (!validWindow) continue;

        // Window scores
        if (aiCount > 0 && humanCount === 0) {
          // AI potential streak
          if (aiCount === k - 2) moveScore += 1800; // 3 in a row building toward 4
          else if (aiCount === k - 3) moveScore += 300;
          else moveScore += 25;
        } else if (humanCount > 0 && aiCount === 0) {
          // Human streak to block
          if (humanCount === k - 2) moveScore += difficulty === 'master' ? 1600 : 1000;
          else if (humanCount === k - 3) moveScore += 250;
          else moveScore += 20;
        }
      }
    }

    scores.set(move, moveScore);
  }

  // Find move with highest score
  let bestScore = -Infinity;
  let bestMoves: number[] = [];

  scores.forEach((score, move) => {
    if (score > bestScore) {
      bestScore = score;
      bestMoves = [move];
    } else if (score === bestScore) {
      bestMoves.push(move);
    }
  });

  if (bestMoves.length === 0) {
    return emptyIndices[Math.floor(Math.random() * emptyIndices.length)];
  }

  // Add small noise on medium/easy so it doesn't play identically every game
  if (difficulty === 'medium' && Math.random() < 0.2 && bestMoves.length > 1) {
    return bestMoves[1];
  }

  return bestMoves[Math.floor(Math.random() * bestMoves.length)];
}

/**
 * Computes AI move based on grid size and difficulty.
 */
export function getAIMove(
  board: CellValue[],
  size: GridSize,
  aiPlayer: Player,
  difficulty: AIDifficulty
): number {
  if (size === 3) {
    if (difficulty === 'master') {
      return getBest3x3Move(board, aiPlayer);
    } else if (difficulty === 'medium') {
      // 75% optimal minimax, 25% heuristic
      return Math.random() < 0.75
        ? getBest3x3Move(board, aiPlayer)
        : getHeuristicMove(board, size, aiPlayer, difficulty);
    } else {
      // Easy: mostly heuristic with random noise
      return getHeuristicMove(board, size, aiPlayer, difficulty);
    }
  }

  return getHeuristicMove(board, size, aiPlayer, difficulty);
}
