import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Volume2, VolumeX, Sparkles } from 'lucide-react';
import { GridSize, GameMode, AIDifficulty, GRID_CONFIGS, WinningLine, CellValue } from '../types/game';
import { Board } from './Board';
import { soundManager } from '../utils/audio';

interface MainMenuProps {
  onStartGame: (size: GridSize, mode: GameMode, difficulty: AIDifficulty) => void;
  isMuted: boolean;
  onToggleMute: () => void;
}

const GRID_SIZES: GridSize[] = [3, 6, 9, 11];

// Curated preview board states representing the user's screenshots
const PREVIEW_BOARDS: Record<GridSize, { board: CellValue[]; winLine: WinningLine }> = {
  3: {
    // Screenshot 1: 3x3 with diagonal win
    board: [
      'O', 'X', 'X',
      'O', 'O', null,
      'X', 'X', 'O'
    ],
    winLine: {
      startIndex: 0,
      endIndex: 8,
      cells: [0, 4, 8],
      direction: 'diagonal-main',
    },
  },
  6: {
    // Screenshot 2 & 3: 6x6 with vertical win (4 Os in column 2)
    board: [
      null, 'X', 'X', null, 'O', null,
      'X', 'O', 'O', 'X', 'X', null,
      null, 'X', 'O', 'O', 'X', 'X',
      null, 'X', 'O', 'X', 'O', 'O',
      null, 'O', 'O', 'X', 'X', null,
      null, null, null, null, null, null,
    ],
    winLine: {
      startIndex: 8,
      endIndex: 26,
      cells: [8, 14, 20, 26],
      direction: 'vertical',
    },
  },
  9: {
    // Screenshot 4: 9x9 with horizontal win (5 Os in row 3)
    board: (() => {
      const b: CellValue[] = Array(81).fill(null);
      // Row 1
      b[1 * 9 + 4] = 'X';
      // Row 2
      b[2 * 9 + 2] = 'X'; b[2 * 9 + 3] = 'X'; b[2 * 9 + 4] = 'O'; b[2 * 9 + 5] = 'X'; b[2 * 9 + 7] = 'X';
      // Row 3 (win line)
      b[3 * 9 + 2] = 'O'; b[3 * 9 + 3] = 'O'; b[3 * 9 + 4] = 'O'; b[3 * 9 + 5] = 'O'; b[3 * 9 + 6] = 'O'; b[3 * 9 + 7] = 'X';
      // Row 4
      b[4 * 9 + 1] = 'O'; b[4 * 9 + 2] = 'X'; b[4 * 9 + 3] = 'O'; b[4 * 9 + 4] = 'X'; b[4 * 9 + 5] = 'O'; b[4 * 9 + 7] = 'X';
      // Row 5
      b[5 * 9 + 2] = 'X'; b[5 * 9 + 3] = 'X'; b[5 * 9 + 4] = 'X'; b[5 * 9 + 5] = 'O'; b[5 * 9 + 6] = 'X'; b[5 * 9 + 7] = 'X'; b[5 * 9 + 8] = 'O';
      // Row 6
      b[6 * 9 + 2] = 'X'; b[6 * 9 + 3] = 'O'; b[6 * 9 + 4] = 'X'; b[6 * 9 + 5] = 'X'; b[6 * 9 + 7] = 'O'; b[6 * 9 + 8] = 'X';
      // Row 7
      b[7 * 9 + 2] = 'X'; b[7 * 9 + 3] = 'O'; b[7 * 9 + 6] = 'O'; b[7 * 9 + 7] = 'O';
      // Row 8
      b[8 * 9 + 3] = 'X'; b[8 * 9 + 6] = 'X'; b[8 * 9 + 7] = 'X';
      return b;
    })(),
    winLine: {
      startIndex: 3 * 9 + 2,
      endIndex: 3 * 9 + 6,
      cells: [3 * 9 + 2, 3 * 9 + 3, 3 * 9 + 4, 3 * 9 + 5, 3 * 9 + 6],
      direction: 'horizontal',
    },
  },
  11: {
    // Screenshot 5: 11x11 with diagonal win
    board: (() => {
      const b: CellValue[] = Array(121).fill(null);
      // Diag win: (7, 2) to (3, 6) -> 5 Os
      b[7 * 11 + 2] = 'O';
      b[6 * 11 + 3] = 'O';
      b[5 * 11 + 4] = 'O';
      b[4 * 11 + 5] = 'O';
      b[3 * 11 + 6] = 'O';
      // Surrounding pieces
      b[2 * 11 + 2] = 'O'; b[2 * 11 + 3] = 'X'; b[2 * 11 + 4] = 'X'; b[2 * 11 + 5] = 'X'; b[2 * 11 + 6] = 'X'; b[2 * 11 + 8] = 'O';
      b[3 * 11 + 4] = 'O'; b[3 * 11 + 5] = 'X';
      b[4 * 11 + 3] = 'X'; b[4 * 11 + 4] = 'X'; b[4 * 11 + 6] = 'X'; b[4 * 11 + 7] = 'X';
      b[5 * 11 + 3] = 'O'; b[5 * 11 + 5] = 'X'; b[5 * 11 + 6] = 'X'; b[5 * 11 + 7] = 'X'; b[5 * 11 + 8] = 'O';
      b[6 * 11 + 4] = 'O'; b[6 * 11 + 5] = 'X'; b[6 * 11 + 6] = 'O';
      b[7 * 11 + 3] = 'X'; b[7 * 11 + 4] = 'O'; b[7 * 11 + 5] = 'X'; b[7 * 11 + 7] = 'X';
      b[8 * 11 + 4] = 'O';
      b[9 * 11 + 3] = 'X'; b[9 * 11 + 4] = 'X';
      return b;
    })(),
    winLine: {
      startIndex: 7 * 11 + 2,
      endIndex: 3 * 11 + 6,
      cells: [7 * 11 + 2, 6 * 11 + 3, 5 * 11 + 4, 4 * 11 + 5, 3 * 11 + 6],
      direction: 'diagonal-anti',
    },
  },
};

export const MainMenu: React.FC<MainMenuProps> = ({
  onStartGame,
  isMuted,
  onToggleMute,
}) => {
  const [selectedSizeIndex, setSelectedSizeIndex] = useState(0);
  const [difficulty, setDifficulty] = useState<AIDifficulty>('medium');
  const [showDifficultySelector, setShowDifficultySelector] = useState(false);

  const currentSize = GRID_SIZES[selectedSizeIndex];
  const preview = PREVIEW_BOARDS[currentSize];

  const handlePrevSize = () => {
    soundManager.playSwitch();
    setSelectedSizeIndex((prev) => (prev > 0 ? prev - 1 : GRID_SIZES.length - 1));
  };

  const handleNextSize = () => {
    soundManager.playSwitch();
    setSelectedSizeIndex((prev) => (prev < GRID_SIZES.length - 1 ? prev + 1 : 0));
  };

  const handleStartMode = (mode: GameMode) => {
    soundManager.playClick();
    onStartGame(currentSize, mode, difficulty);
  };

  return (
    <div className="relative z-10 w-full min-h-screen flex flex-col justify-between items-center px-4 py-4 sm:py-6 max-w-md mx-auto">
      {/* Top Bar with Home Icon and Audio Toggle */}
      <header className="w-full flex items-center justify-between z-20">
        {/* Home icon button */}
        <button
          type="button"
          aria-label="Home"
          onClick={() => {
            soundManager.playClick();
            setSelectedSizeIndex(0);
          }}
          className="w-12 h-12 rounded-2xl border-[2.5px] border-[#1ad1d7] bg-[#0c2e42]/70 flex items-center justify-center text-[#74f8ff] shadow-[0_0_16px_rgba(26,209,215,0.45)] hover:bg-[#12425f]/80 active:scale-95 transition-all duration-150 cursor-pointer"
        >
          <svg className="w-6 h-6 fill-current" viewBox="0 0 24 24">
            <path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z" />
          </svg>
        </button>

        {/* AI Difficulty Button */}
        <button
          type="button"
          onClick={() => {
            soundManager.playClick();
            setShowDifficultySelector(!showDifficultySelector);
          }}
          className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl border text-xs font-semibold tracking-wide transition-all cursor-pointer ${
            showDifficultySelector 
              ? 'border-fuchsia-400 bg-fuchsia-950/70 text-fuchsia-200 shadow-[0_0_12px_rgba(232,121,249,0.4)]'
              : 'border-purple-500/40 bg-purple-950/40 text-purple-200/80 hover:text-white hover:border-purple-400'
          }`}
        >
          <Sparkles className="w-3.5 h-3.5 text-fuchsia-400" />
          <span>AI: {difficulty.toUpperCase()}</span>
        </button>

        {/* Sound Toggle */}
        <button
          type="button"
          aria-label={isMuted ? 'Unmute Audio' : 'Mute Audio'}
          onClick={onToggleMute}
          className="w-12 h-12 rounded-2xl border-[2px] border-purple-400/50 bg-[#1e0e38]/70 flex items-center justify-center text-purple-200 hover:text-white shadow-[0_0_14px_rgba(168,85,247,0.3)] active:scale-95 transition-all duration-150 cursor-pointer"
        >
          {isMuted ? <VolumeX className="w-5 h-5 text-purple-400" /> : <Volume2 className="w-5 h-5 text-cyan-300" />}
        </button>
      </header>

      {/* Popover Difficulty Selector */}
      <AnimatePresence>
        {showDifficultySelector && (
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            className="w-full bg-[#1e0a3b]/95 border border-purple-500/50 rounded-2xl p-2.5 shadow-[0_0_20px_rgba(168,85,247,0.35)] backdrop-blur-md my-1 z-30"
          >
            <div className="text-[11px] font-semibold text-purple-300/80 uppercase tracking-wider mb-2 text-center">
              Bot Intelligence Level
            </div>
            <div className="grid grid-cols-3 gap-1.5">
              {(['easy', 'medium', 'master'] as AIDifficulty[]).map((lvl) => (
                <button
                  key={lvl}
                  onClick={() => {
                    soundManager.playClick();
                    setDifficulty(lvl);
                    setShowDifficultySelector(false);
                  }}
                  className={`py-1.5 px-2 rounded-lg text-xs font-bold capitalize transition-all cursor-pointer ${
                    difficulty === lvl
                      ? 'bg-fuchsia-600 text-white shadow-[0_0_10px_rgba(217,70,239,0.7)]'
                      : 'bg-purple-950/50 text-purple-200/70 hover:bg-purple-900/50 hover:text-white'
                  }`}
                >
                  {lvl}
                </button>
              ))}
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Carousel Area: Grid Size Title + Preview Board + Chevrons */}
      <div className="w-full flex-1 flex flex-col items-center justify-center my-2 sm:my-3">
        {/* Grid Title (3x3, 6x6, 9x9, 11x11) with neon magenta glow */}
        <div className="relative mb-3 flex items-center justify-center">
          <div className="absolute w-32 h-10 bg-fuchsia-600/35 blur-xl rounded-full pointer-events-none" />
          <h1 
            className="font-display text-4xl sm:text-5xl font-extrabold tracking-wider text-[#ffeef8] relative z-10 select-none"
            style={{
              textShadow: '0 0 10px #ff2a85, 0 0 20px #ff2a85, 0 0 35px rgba(255, 42, 133, 0.75)',
            }}
          >
            {GRID_CONFIGS[currentSize].label}
          </h1>
        </div>

        {/* Board Carousel Container with Left and Right Arrows */}
        <div className="w-full relative flex items-center justify-center">
          {/* Left Arrow Button */}
          <button
            type="button"
            aria-label="Previous Grid Size"
            onClick={handlePrevSize}
            className="absolute -left-2 sm:left-0 z-30 p-2 text-[#fffb38] neon-glow-yellow hover:scale-110 active:scale-90 transition-transform duration-150 cursor-pointer focus:outline-none"
          >
            <svg viewBox="0 0 24 24" className="w-10 h-10 sm:w-12 sm:h-12 fill-current drop-shadow-[0_0_10px_rgba(255,235,59,0.9)]">
              <path d="M15.41 7.41L14 6l-6 6 6 6 1.41-1.41L10.83 12z" />
            </svg>
          </button>

          {/* Interactive Preview Board */}
          <div className="w-full max-w-[280px] xs:max-w-[300px] sm:max-w-[340px] px-2">
            <AnimatePresence mode="wait">
              <motion.div
                key={currentSize}
                initial={{ opacity: 0, scale: 0.92 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.92 }}
                transition={{ duration: 0.22, ease: 'easeOut' }}
              >
                <Board
                  size={currentSize}
                  board={preview.board}
                  winningLine={preview.winLine}
                  interactive={false}
                  disabled={true}
                />
              </motion.div>
            </AnimatePresence>
          </div>

          {/* Right Arrow Button */}
          <button
            type="button"
            aria-label="Next Grid Size"
            onClick={handleNextSize}
            className="absolute -right-2 sm:right-0 z-30 p-2 text-[#fffb38] neon-glow-yellow hover:scale-110 active:scale-90 transition-transform duration-150 cursor-pointer focus:outline-none"
          >
            <svg viewBox="0 0 24 24" className="w-10 h-10 sm:w-12 sm:h-12 fill-current drop-shadow-[0_0_10px_rgba(255,235,59,0.9)]">
              <path d="M10 6L8.59 7.41 13.17 12l-4.58 4.59L10 18l6-6z" />
            </svg>
          </button>
        </div>

        {/* Rule badge info */}
        <div className="mt-2 text-xs font-semibold text-fuchsia-300/80 tracking-wide">
          Connect {GRID_CONFIGS[currentSize].winCount} in a row to win
        </div>
      </div>

      {/* Main Game Mode Selection Buttons */}
      <div className="w-full space-y-3.5 mt-2 z-20">
        {/* Mode 1: Player vs Bot */}
        <button
          type="button"
          onClick={() => handleStartMode('ai')}
          className="w-full py-3.5 px-6 rounded-[22px] border-2 border-[#b537f2] bg-[#1a0a38]/80 text-white flex items-center justify-center gap-5 shadow-[0_0_20px_rgba(181,55,242,0.5),inset_0_0_10px_rgba(181,55,242,0.2)] hover:bg-[#280f54]/90 active:scale-[0.98] transition-all duration-150 cursor-pointer group"
        >
          {/* User Icon */}
          <svg 
            viewBox="0 0 24 24" 
            className="w-8 h-8 stroke-current fill-none stroke-[2] stroke-linecap-round stroke-linejoin-round text-[#f472b6] group-hover:scale-105 transition-transform"
          >
            <path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2" />
            <circle cx="12" cy="7" r="4" />
          </svg>

          {/* vs */}
          <span 
            className="font-display text-xl font-bold tracking-wider text-fuchsia-200"
            style={{ textShadow: '0 0 10px rgba(232,121,249,0.8)' }}
          >
            vs
          </span>

          {/* Robot Icon */}
          <svg 
            viewBox="0 0 24 24" 
            className="w-8 h-8 stroke-current fill-none stroke-[2] stroke-linecap-round stroke-linejoin-round text-[#38bdf8] group-hover:scale-105 transition-transform"
          >
            <rect x="3" y="11" width="18" height="10" rx="3" />
            <circle cx="12" cy="5" r="2" />
            <path d="M12 7v4" />
            <line x1="8" y1="15" x2="8.01" y2="15" />
            <line x1="16" y1="15" x2="16.01" y2="15" />
            <path d="M9 18c.8.6 2.2.6 3 0" />
          </svg>
        </button>

        {/* Mode 2: Player vs Player */}
        <button
          type="button"
          onClick={() => handleStartMode('pvp')}
          className="w-full py-3.5 px-6 rounded-[22px] border-2 border-[#b537f2] bg-[#1a0a38]/80 text-white flex items-center justify-center gap-5 shadow-[0_0_20px_rgba(181,55,242,0.5),inset_0_0_10px_rgba(181,55,242,0.2)] hover:bg-[#280f54]/90 active:scale-[0.98] transition-all duration-150 cursor-pointer group"
        >
          {/* User 1 Icon */}
          <svg 
            viewBox="0 0 24 24" 
            className="w-8 h-8 stroke-current fill-none stroke-[2] stroke-linecap-round stroke-linejoin-round text-[#38bdf8] group-hover:scale-105 transition-transform"
          >
            <path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2" />
            <circle cx="12" cy="7" r="4" />
          </svg>

          {/* vs */}
          <span 
            className="font-display text-xl font-bold tracking-wider text-fuchsia-200"
            style={{ textShadow: '0 0 10px rgba(232,121,249,0.8)' }}
          >
            vs
          </span>

          {/* User 2 Icon */}
          <svg 
            viewBox="0 0 24 24" 
            className="w-8 h-8 stroke-current fill-none stroke-[2] stroke-linecap-round stroke-linejoin-round text-[#f472b6] group-hover:scale-105 transition-transform"
          >
            <path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2" />
            <circle cx="12" cy="7" r="4" />
          </svg>
        </button>
      </div>
    </div>
  );
};
