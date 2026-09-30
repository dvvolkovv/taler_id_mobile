// Synthesizes the assistant / translator start cues: bell-like notes in the
// 1–1.6 kHz band (where phone speakers are loudest), peak-normalized to -1 dBFS.
//   node scripts/make_assistant_cues.js assets/audio
const fs = require('fs');
const path = require('path');

const RATE = 44100;

function render(notes, totalMs) {
  const n = Math.round((RATE * totalMs) / 1000);
  const buf = new Float64Array(n);
  for (const { hz, startMs, lenMs } of notes) {
    const s0 = Math.round((RATE * startMs) / 1000);
    const len = Math.round((RATE * lenMs) / 1000);
    for (let i = 0; i < len && s0 + i < n; i++) {
      const t = i / RATE;
      const attack = Math.min(1, t / 0.004);
      const decay = Math.exp(-t / 0.11);
      const release = Math.min(1, (len - i) / (RATE * 0.02));
      const v =
        Math.sin(2 * Math.PI * hz * t) +
        0.35 * Math.sin(2 * Math.PI * hz * 2 * t) +
        0.12 * Math.sin(2 * Math.PI * hz * 3 * t);
      buf[s0 + i] += v * attack * decay * release;
    }
  }
  // Soft saturation raises loudness without clipping, then peak-normalize.
  let peak = 0;
  for (let i = 0; i < n; i++) {
    buf[i] = Math.tanh(1.6 * buf[i]);
    peak = Math.max(peak, Math.abs(buf[i]));
  }
  const gain = (Math.pow(10, -1 / 20) * 32767) / peak;
  const pcm = Buffer.alloc(n * 2);
  for (let i = 0; i < n; i++) pcm.writeInt16LE(Math.round(buf[i] * gain), i * 2);
  return pcm;
}

function wav(pcm) {
  const h = Buffer.alloc(44);
  h.write('RIFF', 0);
  h.writeUInt32LE(36 + pcm.length, 4);
  h.write('WAVE', 8);
  h.write('fmt ', 12);
  h.writeUInt32LE(16, 16);
  h.writeUInt16LE(1, 20);
  h.writeUInt16LE(1, 22);
  h.writeUInt32LE(RATE, 24);
  h.writeUInt32LE(RATE * 2, 28);
  h.writeUInt16LE(2, 32);
  h.writeUInt16LE(16, 34);
  h.write('data', 36);
  h.writeUInt32LE(pcm.length, 40);
  return Buffer.concat([h, pcm]);
}

const out = process.argv[2] || '.';
// Assistant: two rising notes (B5 → E6).
fs.writeFileSync(
  path.join(out, 'assistant_start.wav'),
  wav(render([{ hz: 988, startMs: 0, lenMs: 220 }, { hz: 1319, startMs: 120, lenMs: 300 }], 440)),
);
// Translator: three rising notes (C6 → E6 → G6), audibly different from the assistant.
fs.writeFileSync(
  path.join(out, 'translator_start.wav'),
  wav(render(
    [{ hz: 1047, startMs: 0, lenMs: 200 }, { hz: 1319, startMs: 110, lenMs: 200 }, { hz: 1568, startMs: 220, lenMs: 320 }],
    560,
  )),
);
console.log('written to', path.resolve(out));
