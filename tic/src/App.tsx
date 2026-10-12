/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { GridSize, GameMode, AIDifficulty } from './types/game';
import { Background } from './components/Background';
import { MainMenu } from './components/MainMenu';
import { GameScreen } from './components/GameScreen';
import { soundManager } from './utils/audio';

export default function App() {
  const [screen, setScreen] = useState<'menu' | 'playing'>('menu');
  const [gridSize, setGridSize] = useState<GridSize>(3);
  const [gameMode, setGameMode] = useState<GameMode>('ai');
  const [difficulty, setDifficulty] = useState<AIDifficulty>('medium');
  const [isMuted, setIsMuted] = useState<boolean>(() => soundManager.getMuted());

  const handleToggleMute = () => {
    const nextMuted = soundManager.toggleMute();
    setIsMuted(nextMuted);
  };

  const handleStartGame = (size: GridSize, mode: GameMode, diff: AIDifficulty) => {
    setGridSize(size);
    setGameMode(mode);
    setDifficulty(diff);
    setScreen('playing');
  };

  const handleReturnHome = () => {
    setScreen('menu');
  };

  return (
    <main className="relative min-h-screen w-full overflow-hidden bg-[#09031c] text-white flex items-center justify-center font-sans">
      {/* 2D Retro Synthwave Background */}
      <Background />

      {/* Screen Transitions */}
      <AnimatePresence mode="wait">
        {screen === 'menu' ? (
          <motion.div
            key="menu"
            initial={{ opacity: 0, scale: 0.96 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 1.04 }}
            transition={{ duration: 0.22, ease: 'easeOut' }}
            className="w-full h-full min-h-screen flex items-center justify-center"
          >
            <MainMenu
              onStartGame={handleStartGame}
              isMuted={isMuted}
              onToggleMute={handleToggleMute}
            />
          </motion.div>
        ) : (
          <motion.div
            key="playing"
            initial={{ opacity: 0, scale: 0.96 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 1.04 }}
            transition={{ duration: 0.22, ease: 'easeOut' }}
            className="w-full h-full min-h-screen flex items-center justify-center"
          >
            <GameScreen
              size={gridSize}
              mode={gameMode}
              difficulty={difficulty}
              isMuted={isMuted}
              onToggleMute={handleToggleMute}
              onReturnHome={handleReturnHome}
            />
          </motion.div>
        )}
      </AnimatePresence>
    </main>
  );
}
