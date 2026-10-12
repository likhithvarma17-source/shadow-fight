import React, { useState, useEffect, useCallback, useRef } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { RotateCcw, Volume2, VolumeX, Home, Trophy, Sparkles } from 'lucide-react';
import { GridSize, GameMode, AIDifficulty, Player, CellValue, WinningLine, GameStatus, ScoreBoard, GRID_CONFIGS } from '../types/game';
import { Board } from './Board';
import { checkWin, checkDraw, getAIMove } from '../utils/gameLogic';
import { soundManager } from '../utils/audio';

interface GameScreenProps {
  size: GridSize;
  mode: GameMode;
  difficulty: AIDifficulty;
  isMuted: boolean;
  onToggleMute: () => void;
  onReturnHome: () => void;
}

export const GameScreen: React.FC<GameScreenProps> = ({
  size,
  mode,
  difficulty,
  isMuted,
  onToggleMute,
  onReturnHome,
}) => {
  const [board, setBoard] = useState<CellValue[]>(() => Array(size * size).fill(null));
  const [currentTurn, setCurrentTurn] = useState<Player>('X');
  const [gameStatus, setGameStatus] = useState<GameStatus>('playing');
  const [winner, setWinner] = useState<Player | null>(null);
  const [winningLine, setWinningLine] = useState<WinningLine | null>(null);
  const [lastMoveIndex, setLastMoveIndex] = useState<number | null>(null);
  const [scores, setScores] = useState<ScoreBoard>({ x: 0, o: 0, draws: 0 });
  const [isBotThinking, setIsBotThinking] = useState(false);
  const [moveHistory, setMoveHistory] = useState<Array<{ board: CellValue[]; turn: Player; lastMove: number | null }>>([]);

  const isAIMode = mode === 'ai';
  const humanPlayer: Player = 'X';
  const botPlayer: Player = 'O';

  // Handle a move on the board
  const executeMove = useCallback((index: number, player: Player) => {
    setBoard((prev) => {
      const nextBoard = [...prev];
      nextBoard[index] = player;

      // Save to undo history
      setMoveHistory((h) => [...h, { board: prev, turn: player, lastMove: lastMoveIndex }]);
      setLastMoveIndex(index);
      soundManager.playMove(player);

      // Check for win
      const winResult = checkWin(nextBoard, size);
      if (winResult) {
        setWinner(winResult.winner);
        setWinningLine(winResult.line);
        setGameStatus('won');
        soundManager.playWin();
        setScores((s) => ({
          ...s,
          [winResult.winner.toLowerCase()]: s[winResult.winner.toLowerCase() as 'x' | 'o'] + 1,
        }));
        return nextBoard;
      }

      // Check for draw
      if (checkDraw(nextBoard)) {
        setGameStatus('draw');
        soundManager.playDraw();
        setScores((s) => ({ ...s, draws: s.draws + 1 }));
        return nextBoard;
      }

      // Switch turn
      setCurrentTurn(player === 'X' ? 'O' : 'X');
      return nextBoard;
    });
  }, [size, lastMoveIndex]);

  // Handle cell click by human player
  const handleCellClick = (index: number) => {
    if (gameStatus !== 'playing') return;
    if (board[index] !== null) return;
    if (isAIMode && currentTurn === botPlayer) return;
    if (isBotThinking) return;

    executeMove(index, currentTurn);
  };

  // Bot move trigger
  useEffect(() => {
    if (!isAIMode) return;
    if (gameStatus !== 'playing') return;
    if (currentTurn !== botPlayer) return;

    setIsBotThinking(true);

    const timer = setTimeout(() => {
      const bestMove = getAIMove(board, size, botPlayer, difficulty);
      setIsBotThinking(false);
      if (bestMove !== -1) {
        executeMove(bestMove, botPlayer);
      }
    }, 400 + Math.random() * 200);

    return () => clearTimeout(timer);
  }, [board, currentTurn, gameStatus, isAIMode, botPlayer, size, difficulty, executeMove]);

  // Rematch / Reset current board
  const handleRematch = () => {
    soundManager.playClick();
    setBoard(Array(size * size).fill(null));
    setCurrentTurn('X');
    setGameStatus('playing');
    setWinner(null);
    setWinningLine(null);
    setLastMoveIndex(null);
    setMoveHistory([]);
    setIsBotThinking(false);
  };

  // Undo move
  const handleUndo = () => {
    if (gameStatus !== 'playing' || moveHistory.length === 0 || isBotThinking) return;
    soundManager.playClick();

    if (isAIMode) {
      // In AI mode, undo two moves (bot + human) if possible
      if (moveHistory.length >= 2) {
        const targetState = moveHistory[moveHistory.length - 2];
        setBoard(targetState.board);
        setCurrentTurn(humanPlayer);
        setLastMoveIndex(targetState.lastMove);
        setMoveHistory((h) => h.slice(0, -2));
      } else {
        const targetState = moveHistory[0];
        setBoard(targetState.board);
        setCurrentTurn(humanPlayer);
        setLastMoveIndex(null);
        setMoveHistory([]);
      }
    } else {
      // PvP mode: undo 1 move
      const lastState = moveHistory[moveHistory.length - 1];
      setBoard(lastState.board);
      setCurrentTurn(lastState.turn);
      setLastMoveIndex(lastState.lastMove);
      setMoveHistory((h) => h.slice(0, -1));
    }
  };

  return (
    <div className="relative z-10 w-full min-h-screen flex flex-col justify-between items-center px-4 py-3 sm:py-5 max-w-md mx-auto">
      {/* Top Header Bar */}
      <header className="w-full flex items-center justify-between z-20">
        {/* Home Button */}
        <button
          type="button"
          aria-label="Return to Main Menu"
          onClick={() => {
            soundManager.playClick();
            onReturnHome();
          }}
          className="w-11 h-11 rounded-2xl border-[2px] border-[#1ad1d7] bg-[#0c2e42]/70 flex items-center justify-center text-[#74f8ff] shadow-[0_0_14px_rgba(26,209,215,0.45)] hover:bg-[#12425f]/80 active:scale-95 transition-all duration-150 cursor-pointer"
        >
          <Home className="w-5 h-5 fill-current" />
        </button>

        {/* Center Mode & Size Pill */}
        <div className="flex items-center gap-2 px-3.5 py-1.5 rounded-full border border-purple-500/40 bg-[#190936]/80 shadow-[0_0_12px_rgba(168,85,247,0.3)]">
          <span 
            className="font-display text-sm font-bold tracking-wider text-pink-300"
            style={{ textShadow: '0 0 8px rgba(244,114,182,0.8)' }}
          >
            {GRID_CONFIGS[size].label}
          </span>
          <span className="text-purple-400/60 text-xs">·</span>
          <span className="text-xs font-semibold text-purple-200">
            {isAIMode ? `vs Bot (${difficulty})` : '2 Players'}
          </span>
        </div>

        {/* Sound Toggle */}
        <button
          type="button"
          aria-label={isMuted ? 'Unmute Audio' : 'Mute Audio'}
          onClick={onToggleMute}
          className="w-11 h-11 rounded-2xl border-[2px] border-purple-400/50 bg-[#1e0e38]/70 flex items-center justify-center text-purple-200 hover:text-white shadow-[0_0_12px_rgba(168,85,247,0.3)] active:scale-95 transition-all duration-150 cursor-pointer"
        >
          {isMuted ? <VolumeX className="w-5 h-5 text-purple-400" /> : <Volume2 className="w-5 h-5 text-cyan-300" />}
        </button>
      </header>

      {/* Scoreboard and Turn Indicator */}
      <div className="w-full my-2">
        <div className="w-full bg-[#180838]/85 border border-[#b537f2]/50 rounded-2xl p-2.5 sm:p-3 shadow-[0_0_18px_rgba(181,55,242,0.35)] backdrop-blur-sm">
          {/* Players Strip */}
          <div className="grid grid-cols-3 items-center">
            {/* Player X Card */}
            <div 
              className={`flex flex-col items-center p-1.5 rounded-xl transition-all ${
                currentTurn === 'X' && gameStatus === 'playing'
                  ? 'bg-cyan-950/60 border border-cyan-400/60 shadow-[0_0_12px_rgba(38,180,255,0.4)]'
                  : 'opacity-75'
              }`}
            >
              <div className="flex items-center gap-1.5">
                <span 
                  className="font-display font-extrabold text-base text-[#26b4ff]"
                  style={{ textShadow: '0 0 8px #26b4ff' }}
                >
                  X
                </span>
                <span className="text-xs font-bold text-cyan-200">
                  {isAIMode ? 'You' : 'Player 1'}
                </span>
              </div>
              <span className="font-mono text-lg font-bold text-white tabular-nums">
                {scores.x}
              </span>
            </div>

            {/* Draws in center */}
            <div className="flex flex-col items-center">
              <span className="text-[11px] font-semibold text-purple-300/70 uppercase tracking-wider">
                Draws
              </span>
              <span className="font-mono text-base font-bold text-purple-200 tabular-nums">
                {scores.draws}
              </span>
            </div>

            {/* Player O Card */}
            <div 
              className={`flex flex-col items-center p-1.5 rounded-xl transition-all ${
                currentTurn === 'O' && gameStatus === 'playing'
                  ? 'bg-rose-950/60 border border-rose-400/60 shadow-[0_0_12px_rgba(255,59,86,0.4)]'
                  : 'opacity-75'
              }`}
            >
              <div className="flex items-center gap-1.5">
                <span 
                  className="font-display font-extrabold text-base text-[#ff3b56]"
                  style={{ textShadow: '0 0 8px #ff3b56' }}
                >
                  O
                </span>
                <span className="text-xs font-bold text-rose-200">
                  {isAIMode ? 'Bot' : 'Player 2'}
                </span>
              </div>
              <span className="font-mono text-lg font-bold text-white tabular-nums">
                {scores.o}
              </span>
            </div>
          </div>

          {/* Current Turn Status Bar */}
          <div className="mt-2 pt-2 border-t border-purple-500/30 flex items-center justify-center gap-2">
            {gameStatus === 'playing' ? (
              <>
                <div 
                  className={`w-2 h-2 rounded-full animate-ping ${
                    currentTurn === 'X' ? 'bg-cyan-400' : 'bg-rose-400'
                  }`}
                />
                <span className="text-xs font-bold tracking-wide text-white">
                  {isAIMode
                    ? currentTurn === 'X'
                      ? 'Your turn (X)'
                      : isBotThinking
                      ? 'Bot is calculating move...'
                      : "Bot's turn (O)"
                    : `Player ${currentTurn}'s Turn`}
                </span>
              </>
            ) : gameStatus === 'won' ? (
              <span 
                className="text-xs font-extrabold uppercase tracking-wider text-yellow-300 flex items-center gap-1.5"
                style={{ textShadow: '0 0 10px rgba(255,235,59,0.8)' }}
              >
                <Trophy className="w-3.5 h-3.5 text-yellow-300" />
                {isAIMode
                  ? winner === 'X'
                    ? 'Victory! You Won!'
                    : 'Bot Won this round!'
                  : `Player ${winner} Won!`}
              </span>
            ) : (
              <span className="text-xs font-bold uppercase tracking-wider text-purple-300">
                Round Ended in a Draw!
              </span>
            )}
          </div>
        </div>
      </div>

      {/* Interactive Game Board */}
      <div className="w-full flex items-center justify-center my-auto py-2">
        <Board
          size={size}
          board={board}
          onCellClick={handleCellClick}
          winningLine={winningLine}
          disabled={gameStatus !== 'playing' || (isAIMode && currentTurn === botPlayer)}
          interactive={true}
          lastMoveIndex={lastMoveIndex}
          turn={currentTurn}
        />
      </div>

      {/* In-Game Action Bar */}
      <div className="w-full flex items-center justify-between gap-3 mt-2 z-20">
        {/* Undo button */}
        <button
          type="button"
          onClick={handleUndo}
          disabled={gameStatus !== 'playing' || moveHistory.length === 0 || isBotThinking}
          className={`flex-1 py-2.5 px-3 rounded-2xl border text-xs font-bold tracking-wide flex items-center justify-center gap-1.5 transition-all duration-150 cursor-pointer ${
            gameStatus === 'playing' && moveHistory.length > 0 && !isBotThinking
              ? 'border-purple-400/50 bg-[#1f0d3d]/80 text-purple-200 hover:bg-[#2b1254] active:scale-95 shadow-[0_0_10px_rgba(168,85,247,0.3)]'
              : 'border-purple-900/40 bg-purple-950/20 text-purple-400/40 cursor-not-allowed'
          }`}
        >
          <RotateCcw className="w-3.5 h-3.5" />
          <span>Undo</span>
        </button>

        {/* Rematch / Play Again button */}
        <button
          type="button"
          onClick={handleRematch}
          className="flex-[2] py-2.5 px-4 rounded-2xl border-2 border-[#b537f2] bg-gradient-to-r from-[#9333ea]/80 to-[#c026d3]/80 text-white text-xs font-extrabold uppercase tracking-wider flex items-center justify-center gap-2 shadow-[0_0_18px_rgba(181,55,242,0.5)] hover:brightness-110 active:scale-95 transition-all duration-150 cursor-pointer"
        >
          <Sparkles className="w-4 h-4 text-yellow-300" />
          <span>{gameStatus === 'playing' ? 'Restart Board' : 'Play Rematch'}</span>
        </button>
      </div>

      {/* Victory / Draw Overlay Modal */}
      <AnimatePresence>
        {gameStatus !== 'playing' && (
          <motion.div
            initial={{ opacity: 0, scale: 0.88, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.88, y: 20 }}
            transition={{ duration: 0.28, ease: [0.16, 1, 0.3, 1] }}
            className="fixed inset-x-4 bottom-24 sm:bottom-28 max-w-sm mx-auto z-40 bg-[#160633]/95 border-2 border-[#ff2a85] rounded-3xl p-5 text-center shadow-[0_0_35px_rgba(255,42,133,0.7),inset_0_0_15px_rgba(255,42,133,0.3)] backdrop-blur-md"
          >
            {/* Header Icon & Title */}
            <div className="flex flex-col items-center mb-3">
              <div className="w-12 h-12 rounded-2xl bg-fuchsia-950/60 border border-fuchsia-400/60 flex items-center justify-center mb-2 shadow-[0_0_15px_rgba(217,70,239,0.5)]">
                {gameStatus === 'won' ? (
                  <Trophy className="w-6 h-6 text-yellow-300" />
                ) : (
                  <Sparkles className="w-6 h-6 text-cyan-300" />
                )}
              </div>

              <h2 
                className="font-display text-2xl font-black tracking-wide text-white"
                style={{
                  textShadow: gameStatus === 'won' ? '0 0 12px #ff2a85' : '0 0 10px #a855f7',
                }}
              >
                {gameStatus === 'won'
                  ? isAIMode
                    ? winner === 'X'
                      ? 'VICTORY!'
                      : 'DEFEAT'
                    : `PLAYER ${winner} WINS!`
                  : "IT'S A DRAW!"}
              </h2>

              <p className="text-xs text-purple-200/80 mt-1">
                {gameStatus === 'won'
                  ? isAIMode
                    ? winner === 'X'
                      ? 'You connected the winning line!'
                      : 'The Bot outmaneuvered the board.'
                    : `Connected ${GRID_CONFIGS[size].winCount} symbols in a row.`
                  : 'Well fought! Both players held their ground.'}
              </p>
            </div>

            {/* Quick Action Buttons */}
            <div className="flex items-center gap-2.5 mt-4">
              <button
                type="button"
                onClick={() => {
                  soundManager.playClick();
                  onReturnHome();
                }}
                className="flex-1 py-2.5 px-3 rounded-xl border border-purple-400/40 bg-purple-950/60 text-purple-200 text-xs font-bold hover:bg-purple-900/60 hover:text-white transition-all cursor-pointer"
              >
                Menu
              </button>

              <button
                type="button"
                onClick={handleRematch}
                className="flex-[2] py-2.5 px-4 rounded-xl border-2 border-[#ffe600] bg-gradient-to-r from-amber-500 to-yellow-400 text-slate-950 text-xs font-extrabold uppercase tracking-wider shadow-[0_0_15px_rgba(255,230,0,0.6)] hover:brightness-105 active:scale-95 transition-all cursor-pointer"
              >
                Play Again
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};
