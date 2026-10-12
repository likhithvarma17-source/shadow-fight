export type GridSize = 3 | 6 | 9 | 11;

export type Player = 'X' | 'O';

export type CellValue = Player | null;

export type GameMode = 'ai' | 'pvp';

export type AIDifficulty = 'easy' | 'medium' | 'master';

export interface WinningLine {
  startIndex: number;
  endIndex: number;
  cells: number[];
  direction: 'horizontal' | 'vertical' | 'diagonal-main' | 'diagonal-anti';
}

export type GameStatus = 'playing' | 'won' | 'draw';

export interface ScoreBoard {
  x: number;
  o: number;
  draws: number;
}

export interface GridConfig {
  size: GridSize;
  winCount: number; // 3 in a row for 3x3, 4 for 6x6, 5 for 9x9 and 11x11
  label: string;
}

export const GRID_CONFIGS: Record<GridSize, GridConfig> = {
  3: { size: 3, winCount: 3, label: '3x3' },
  6: { size: 6, winCount: 4, label: '6x6' },
  9: { size: 9, winCount: 5, label: '9x9' },
  11: { size: 11, winCount: 5, label: '11x11' },
};
