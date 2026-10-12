import React, { useMemo } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { GridSize, CellValue, WinningLine, Player } from '../types/game';

interface BoardProps {
  size: GridSize;
  board: CellValue[];
  onCellClick?: (index: number) => void;
  winningLine: WinningLine | null;
  disabled?: boolean;
  interactive?: boolean;
  lastMoveIndex?: number | null;
  turn?: Player;
}

export const Board: React.FC<BoardProps> = ({
  size,
  board,
  onCellClick,
  winningLine,
  disabled = false,
  interactive = true,
  lastMoveIndex = null,
  turn = 'X',
}) => {
  // Grid coordinates mapping
  const cellPositions = useMemo(() => {
    const positions: Array<{ r: number; c: number; xPercent: number; yPercent: number }> = [];
    const stepPercent = 100 / size;
    const halfStep = stepPercent / 2;

    for (let r = 0; r < size; r++) {
      for (let c = 0; c < size; c++) {
        positions.push({
          r,
          c,
          xPercent: c * stepPercent + halfStep,
          yPercent: r * stepPercent + halfStep,
        });
      }
    }
    return positions;
  }, [size]);

  // Winning line coordinates in SVG viewBox 0..100
  const winLineCoords = useMemo(() => {
    if (!winningLine) return null;
    const start = cellPositions[winningLine.startIndex];
    const end = cellPositions[winningLine.endIndex];
    if (!start || !end) return null;

    // Extend line slightly past the center of start and end cells
    const dx = end.xPercent - start.xPercent;
    const dy = end.yPercent - start.yPercent;
    const len = Math.hypot(dx, dy);

    if (len === 0) return null;
    const extend = (100 / size) * 0.35;
    const normX = dx / len;
    const normY = dy / len;

    return {
      x1: Math.max(2, Math.min(98, start.xPercent - normX * extend)),
      y1: Math.max(2, Math.min(98, start.yPercent - normY * extend)),
      x2: Math.max(2, Math.min(98, end.xPercent + normX * extend)),
      y2: Math.max(2, Math.min(98, end.yPercent + normY * extend)),
    };
  }, [winningLine, cellPositions, size]);

  // Font/stroke size calculations based on grid density
  const strokeWidth = size === 3 ? 4.2 : size === 6 ? 3.4 : size === 9 ? 2.6 : 2.2;
  const paddingPercent = size === 3 ? 20 : size === 6 ? 16 : 14;

  return (
    <div className="relative w-full aspect-square max-w-[340px] xs:max-w-[360px] sm:max-w-[400px] md:max-w-[430px] mx-auto select-none">
      {/* Outer Neon Board Frame */}
      <div 
        className="w-full h-full rounded-[28px] sm:rounded-[34px] p-2 sm:p-2.5 relative overflow-hidden backdrop-blur-sm"
        style={{
          border: '3.5px solid #ff2a85',
          backgroundColor: 'rgba(19, 7, 43, 0.88)',
          boxShadow: '0 0 24px rgba(255, 42, 133, 0.65), 0 0 50px rgba(255, 42, 133, 0.22), inset 0 0 16px rgba(255, 42, 133, 0.28)',
        }}
      >
        {/* Cell Grid Container */}
        <div 
          className="w-full h-full grid relative"
          style={{
            gridTemplateColumns: `repeat(${size}, minmax(0, 1fr))`,
            gridTemplateRows: `repeat(${size}, minmax(0, 1fr))`,
          }}
        >
          {/* Inner Sharp Grid Dividing Lines (rendered via SVG for sub-pixel sharpness) */}
          <svg className="absolute inset-0 w-full h-full pointer-events-none z-10" xmlns="http://www.w3.org/2000/svg">
            {Array.from({ length: size - 1 }).map((_, i) => {
              const posPercent = ((i + 1) * 100) / size;
              return (
                <React.Fragment key={`grid-line-${i}`}>
                  {/* Vertical grid line */}
                  <line
                    x1={`${posPercent}%`}
                    y1="2%"
                    x2={`${posPercent}%`}
                    y2="98%"
                    stroke="#ec4899"
                    strokeWidth={size >= 9 ? "1.2" : "1.8"}
                    strokeOpacity="0.45"
                    strokeLinecap="round"
                  />
                  {/* Horizontal grid line */}
                  <line
                    x1="2%"
                    y1={`${posPercent}%`}
                    x2="98%"
                    y2={`${posPercent}%`}
                    stroke="#ec4899"
                    strokeWidth={size >= 9 ? "1.2" : "1.8"}
                    strokeOpacity="0.45"
                    strokeLinecap="round"
                  />
                </React.Fragment>
              );
            })}
          </svg>

          {/* Interactive Cells */}
          {board.map((cellValue, idx) => {
            const isWinningCell = winningLine?.cells.includes(idx) ?? false;
            const isLastMove = lastMoveIndex === idx;
            const row = Math.floor(idx / size);
            const col = idx % size;

            return (
              <button
                key={`cell-${idx}`}
                type="button"
                aria-label={`Row ${row + 1}, Column ${col + 1}${cellValue ? `, ${cellValue}` : ', empty'}`}
                disabled={!interactive || disabled || cellValue !== null}
                onClick={() => onCellClick && onCellClick(idx)}
                className={`group relative w-full h-full flex items-center justify-center focus:outline-none transition-colors duration-150 z-20 ${
                  !interactive ? 'cursor-default' : cellValue === null && !disabled ? 'cursor-pointer hover:bg-fuchsia-500/10 active:bg-fuchsia-500/20' : 'cursor-default'
                }`}
              >
                {/* Subtle highlight on cell when hovered if empty */}
                {interactive && !disabled && cellValue === null && (
                  <div className="absolute inset-1 rounded-lg opacity-0 group-hover:opacity-100 transition-opacity bg-white/5 pointer-events-none" />
                )}

                {/* Render Symbol X or O */}
                {cellValue === 'X' && (
                  <SymbolX
                    strokeWidth={strokeWidth}
                    paddingPercent={paddingPercent}
                    isWinning={isWinningCell}
                    isNew={isLastMove}
                  />
                )}

                {cellValue === 'O' && (
                  <SymbolO
                    strokeWidth={strokeWidth}
                    paddingPercent={paddingPercent}
                    isWinning={isWinningCell}
                    isNew={isLastMove}
                  />
                )}
              </button>
            );
          })}

          {/* Winning Line Overlay */}
          <AnimatePresence>
            {winLineCoords && (
              <svg 
                className="absolute inset-0 w-full h-full pointer-events-none z-30" 
                viewBox="0 0 100 100" 
                preserveAspectRatio="none"
              >
                <defs>
                  {/* Intense Neon Yellow Glow Filter */}
                  <filter id="winGlow" x="-20%" y="-20%" width="140%" height="140%">
                    <feGaussianBlur stdDeviation="1.8" result="blur1" />
                    <feGaussianBlur stdDeviation="3.6" result="blur2" />
                    <feMerge>
                      <feMergeNode in="blur2" />
                      <feMergeNode in="blur1" />
                      <feMergeNode in="SourceGraphic" />
                    </feMerge>
                  </filter>
                </defs>

                {/* Outer glowing halo line */}
                <motion.line
                  x1={winLineCoords.x1}
                  y1={winLineCoords.y1}
                  x2={winLineCoords.x2}
                  y2={winLineCoords.y2}
                  stroke="#ffe600"
                  strokeWidth="5"
                  strokeOpacity="0.85"
                  strokeLinecap="round"
                  filter="url(#winGlow)"
                  initial={{ pathLength: 0, opacity: 0 }}
                  animate={{ pathLength: 1, opacity: 1 }}
                  transition={{ duration: 0.45, ease: [0.16, 1, 0.3, 1] }}
                />

                {/* Crisp white/yellow core line */}
                <motion.line
                  x1={winLineCoords.x1}
                  y1={winLineCoords.y1}
                  x2={winLineCoords.x2}
                  y2={winLineCoords.y2}
                  stroke="#ffffff"
                  strokeWidth="2.8"
                  strokeLinecap="round"
                  initial={{ pathLength: 0, opacity: 0 }}
                  animate={{ pathLength: 1, opacity: 1 }}
                  transition={{ duration: 0.42, ease: [0.16, 1, 0.3, 1] }}
                />
              </svg>
            )}
          </AnimatePresence>
        </div>
      </div>
    </div>
  );
};

// --- SYMBOL X (Electric Neon Cyan) ---
interface SymbolProps {
  strokeWidth: number;
  paddingPercent: number;
  isWinning?: boolean;
  isNew?: boolean;
}

const SymbolX: React.FC<SymbolProps> = ({ strokeWidth, paddingPercent, isWinning, isNew }) => {
  const p = paddingPercent;
  const end = 100 - p;

  return (
    <motion.div
      initial={isNew ? { scale: 0.6, opacity: 0 } : false}
      animate={{ 
        scale: isWinning ? [1, 1.14, 1] : 1, 
        opacity: 1,
      }}
      transition={
        isWinning 
          ? { repeat: Infinity, duration: 1.2, ease: 'easeInOut' }
          : { duration: 0.22, ease: [0.175, 0.885, 0.32, 1.275] }
      }
      className="w-full h-full flex items-center justify-center p-1"
    >
      <svg
        viewBox="0 0 100 100"
        className="w-full h-full"
        style={{
          filter: isWinning
            ? 'drop-shadow(0 0 12px #26b4ff) drop-shadow(0 0 20px #26b4ff)'
            : 'drop-shadow(0 0 6px #26b4ff)',
        }}
      >
        <defs>
          <linearGradient id="neonBlueGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#80e1ff" />
            <stop offset="100%" stopColor="#1a9dff" />
          </linearGradient>
        </defs>

        {/* First diagonal stroke */}
        <motion.line
          x1={p}
          y1={p}
          x2={end}
          y2={end}
          stroke="url(#neonBlueGrad)"
          strokeWidth={strokeWidth}
          strokeLinecap="round"
          initial={isNew ? { pathLength: 0 } : false}
          animate={{ pathLength: 1 }}
          transition={{ duration: 0.18, ease: 'easeOut' }}
        />

        {/* Second diagonal stroke */}
        <motion.line
          x1={end}
          y1={p}
          x2={p}
          y2={end}
          stroke="url(#neonBlueGrad)"
          strokeWidth={strokeWidth}
          strokeLinecap="round"
          initial={isNew ? { pathLength: 0 } : false}
          animate={{ pathLength: 1 }}
          transition={{ duration: 0.18, delay: isNew ? 0.08 : 0, ease: 'easeOut' }}
        />
      </svg>
    </motion.div>
  );
};

// --- SYMBOL O (Vibrant Neon Coral / Crimson) ---
const SymbolO: React.FC<SymbolProps> = ({ strokeWidth, paddingPercent, isWinning, isNew }) => {
  const radius = (100 - paddingPercent * 2) / 2;

  return (
    <motion.div
      initial={isNew ? { scale: 0.6, opacity: 0 } : false}
      animate={{ 
        scale: isWinning ? [1, 1.14, 1] : 1, 
        opacity: 1,
      }}
      transition={
        isWinning 
          ? { repeat: Infinity, duration: 1.2, ease: 'easeInOut' }
          : { duration: 0.22, ease: [0.175, 0.885, 0.32, 1.275] }
      }
      className="w-full h-full flex items-center justify-center p-1"
    >
      <svg
        viewBox="0 0 100 100"
        className="w-full h-full"
        style={{
          filter: isWinning
            ? 'drop-shadow(0 0 12px #ff3b56) drop-shadow(0 0 20px #ff3b56)'
            : 'drop-shadow(0 0 6px #ff3b56)',
        }}
      >
        <defs>
          <linearGradient id="neonRedGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#ff7a88" />
            <stop offset="100%" stopColor="#ff2848" />
          </linearGradient>
        </defs>

        <motion.circle
          cx="50"
          cy="50"
          r={radius}
          fill="none"
          stroke="url(#neonRedGrad)"
          strokeWidth={strokeWidth}
          strokeLinecap="round"
          initial={isNew ? { pathLength: 0, rotate: -90 } : false}
          animate={{ pathLength: 1, rotate: 0 }}
          transition={{ duration: 0.24, ease: 'easeOut' }}
        />
      </svg>
    </motion.div>
  );
};
