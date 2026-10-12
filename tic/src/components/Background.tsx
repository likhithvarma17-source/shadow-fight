import React, { useMemo } from 'react';

export const Background: React.FC = () => {
  // Generate deterministic stars
  const stars = useMemo(() => {
    return Array.from({ length: 45 }).map((_, i) => ({
      id: i,
      x: (i * 37) % 100,
      y: (i * 23) % 65,
      size: (i % 3 === 0 ? 2 : 1.2),
      opacity: 0.2 + ((i % 5) * 0.15),
      animDelay: `${(i % 7) * 0.7}s`,
    }));
  }, []);

  return (
    <div className="fixed inset-0 pointer-events-none overflow-hidden select-none z-0 bg-[#09031c]">
      {/* Deep synthwave sky gradient */}
      <div 
        className="absolute inset-0"
        style={{
          background: 'radial-gradient(ellipse 120% 80% at 50% 10%, #1c0a3d 0%, #0c0324 55%, #050114 100%)'
        }}
      />

      {/* Twinkling star field */}
      <svg className="absolute inset-0 w-full h-full" xmlns="http://www.w3.org/2000/svg">
        {stars.map((star) => (
          <circle
            key={star.id}
            cx={`${star.x}%`}
            cy={`${star.y}%`}
            r={star.size}
            fill="#e0d4ff"
            opacity={star.opacity}
            style={{
              animation: `pulse ${(2 + (star.id % 4))}s infinite ease-in-out`,
              animationDelay: star.animDelay,
            }}
          />
        ))}
      </svg>

      {/* Distant retro horizon glow */}
      <div 
        className="absolute bottom-[22%] left-1/2 -translate-x-1/2 w-[380px] sm:w-[540px] h-[180px] rounded-full blur-[70px] pointer-events-none opacity-60"
        style={{
          background: 'radial-gradient(circle, rgba(236, 72, 153, 0.45) 0%, rgba(168, 85, 247, 0.25) 50%, transparent 80%)'
        }}
      />

      {/* Synthwave Island & Palm Tree Silhouette */}
      <div className="absolute bottom-[24%] left-1/2 -translate-x-1/2 w-[340px] sm:w-[420px] h-[90px] opacity-35 pointer-events-none flex items-end justify-center">
        <svg viewBox="0 0 300 80" className="w-full h-full" fill="#070216">
          {/* Subtle island hill */}
          <path d="M 40 80 Q 150 48 260 80 Z" />
          
          {/* Left Palm tree */}
          <path d="M 142 65 Q 138 40 134 25 Q 133 20 132 15 L 134 15 Q 136 21 140 40 Q 144 58 145 65 Z" />
          {/* Palm leaves */}
          <path d="M 133 16 Q 115 15 108 26 Q 120 22 133 18 Z" />
          <path d="M 133 16 Q 120 8 112 14 Q 122 13 133 17 Z" />
          <path d="M 133 16 Q 136 5 145 10 Q 139 12 133 17 Z" />
          <path d="M 133 16 Q 148 12 155 22 Q 144 19 133 17 Z" />

          {/* Right Palm tree */}
          <path d="M 152 66 Q 158 45 163 28 Q 165 24 167 18 L 165 18 Q 163 24 157 44 Q 152 59 150 66 Z" />
          {/* Right leaves */}
          <path d="M 166 19 Q 152 14 148 20 Q 157 18 166 20 Z" />
          <path d="M 166 19 Q 170 8 178 12 Q 173 15 166 20 Z" />
          <path d="M 166 19 Q 182 15 188 25 Q 178 22 166 21 Z" />
        </svg>
      </div>

      {/* Perspective retro floor grid */}
      <div className="absolute bottom-0 left-0 right-0 h-[28vh] min-h-[140px] overflow-hidden pointer-events-none">
        <div 
          className="w-[200%] -left-[50%] h-[240%] absolute bottom-0 synthwave-grid"
          style={{
            maskImage: 'linear-gradient(to top, rgba(0,0,0,1) 0%, rgba(0,0,0,0.85) 45%, rgba(0,0,0,0) 95%)',
            WebkitMaskImage: 'linear-gradient(to top, rgba(0,0,0,1) 0%, rgba(0,0,0,0.85) 45%, rgba(0,0,0,0) 95%)',
          }}
        />
        {/* Subtle grid horizon neon line */}
        <div 
          className="absolute top-0 left-0 right-0 h-[1.5px] opacity-40"
          style={{
            background: 'linear-gradient(90deg, transparent 0%, #ec4899 30%, #a855f7 50%, #ec4899 70%, transparent 100%)',
            boxShadow: '0 0 10px #ec4899'
          }}
        />
      </div>
    </div>
  );
};
