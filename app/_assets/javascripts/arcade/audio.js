// Every sound is synthesised with the Web Audio API: oscillators for tones,
// a filtered noise buffer for glitches. No audio files are loaded.
export class Sfx {
  constructor() {
    this.ctx = new AudioContext();
    this.master = this.ctx.createGain();
    this.master.gain.value = 0.2;
    this.master.connect(this.ctx.destination);
    this.muted = false;

    const length = this.ctx.sampleRate;
    this.noiseBuffer = this.ctx.createBuffer(1, length, this.ctx.sampleRate);
    const data = this.noiseBuffer.getChannelData(0);
    for (let i = 0; i < length; i++) data[i] = Math.random() * 2 - 1;
  }

  resume() {
    if (this.ctx.state === "suspended") this.ctx.resume();
  }

  toggleMute() {
    this.muted = !this.muted;
    this.master.gain.value = this.muted ? 0 : 0.2;
  }

  close() {
    this.ctx.close();
  }

  tone({ freq, to = freq, dur, type = "square", vol = 0.5, delay = 0 }) {
    const start = this.ctx.currentTime + delay;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(freq, start);
    if (to !== freq) osc.frequency.exponentialRampToValueAtTime(to, start + dur);
    gain.gain.setValueAtTime(vol, start);
    gain.gain.exponentialRampToValueAtTime(0.001, start + dur);
    osc.connect(gain).connect(this.master);
    osc.start(start);
    osc.stop(start + dur);
  }

  noise({ dur, freq = 1000, q = 1, vol = 0.3, delay = 0 }) {
    const start = this.ctx.currentTime + delay;
    const src = this.ctx.createBufferSource();
    const filter = this.ctx.createBiquadFilter();
    const gain = this.ctx.createGain();
    src.buffer = this.noiseBuffer;
    filter.type = "bandpass";
    filter.frequency.value = freq;
    filter.Q.value = q;
    gain.gain.setValueAtTime(vol, start);
    gain.gain.exponentialRampToValueAtTime(0.001, start + dur);
    src.connect(filter).connect(gain).connect(this.master);
    src.start(start);
    src.stop(start + dur);
  }

  arpeggio(notes, step, type = "square", vol = 0.35) {
    notes.forEach((freq, i) => this.tone({ freq, dur: step * 1.5, type, vol, delay: i * step }));
  }

  type() {
    this.tone({ freq: 1400 + Math.random() * 400, dur: 0.02, vol: 0.12 });
  }

  jump() {
    this.tone({ freq: 280, to: 620, dur: 0.12, vol: 0.3 });
  }

  land() {
    this.noise({ dur: 0.06, freq: 300, vol: 0.25 });
  }

  drop() {
    this.tone({ freq: 500, to: 200, dur: 0.1, type: "triangle", vol: 0.3 });
  }

  patchTick() {
    this.tone({ freq: 880, dur: 0.03, vol: 0.15 });
  }

  patched() {
    this.arpeggio([523, 659, 784, 1047], 0.07);
  }

  corrupt() {
    this.noise({ dur: 0.05, freq: 2500 + Math.random() * 2000, q: 8, vol: 0.12 });
  }

  orb() {
    this.tone({ freq: 160, to: 90, dur: 0.25, type: "sawtooth", vol: 0.15 });
  }

  hit() {
    this.noise({ dur: 0.2, freq: 600, q: 0.7, vol: 0.4 });
    this.tone({ freq: 440, to: 110, dur: 0.3, type: "square", vol: 0.3 });
  }

  start() {
    this.arpeggio([262, 392, 523, 784], 0.09, "triangle", 0.4);
  }

  flag() {
    this.tone({ freq: 330, to: 990, dur: 1.2, type: "triangle", vol: 0.25 });
  }

  win() {
    this.arpeggio([523, 659, 784, 1047, 784, 1047, 1319], 0.1);
  }

  lose() {
    this.arpeggio([392, 311, 262, 196, 147], 0.16, "sawtooth", 0.25);
  }
}
