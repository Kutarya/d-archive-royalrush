"""Original deterministic synthesis; no downloaded recordings or dependencies."""
from array import array
from pathlib import Path
import hashlib
import json
import math
import random
import wave

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "content" / "audio"
RATE = 24000


def frequency(note):
    return 440.0 * 2 ** ((note - 69) / 12)


def tone(buffer, start, duration, note, level=0.12, voice="bell"):
    offset = int(start * RATE)
    size = int(duration * RATE)
    f = frequency(note)
    for j in range(size):
        if offset + j >= len(buffer):
            break
        t = j / RATE
        fade = min(1, t / 0.008) * min(1, (duration - t) / 0.035)
        envelope = fade * math.exp(-t * (5 if voice == "bell" else 1.5))
        carrier = math.sin(2 * math.pi * f * t)
        carrier += 0.22 * math.sin(2 * math.pi * f * 2 * t)
        carrier += 0.08 * math.sin(2 * math.pi * f * 3 * t)
        buffer[offset + j] += carrier * envelope * level


def percussion(buffer, start, kick):
    rng = random.Random(52 + int(start * 100))
    size = int((0.18 if kick else 0.07) * RATE)
    offset = int(start * RATE)
    for j in range(size):
        if offset + j >= len(buffer):
            break
        t = j / RATE
        envelope = math.exp(-t * (28 if kick else 70))
        value = math.sin(2 * math.pi * (80 * t - 65 * t * t)) if kick else rng.uniform(-1, 1)
        buffer[offset + j] += value * envelope * (0.13 if kick else 0.035)


def loop(bpm, melody, bass):
    beat = 60 / bpm
    length = 32 * beat
    buffer = [0.0] * int(length * RATE)
    for i in range(64):
        tone(buffer, i * beat / 2, beat * 0.7, melody[i % len(melody)], 0.105)
    for i in range(32):
        tone(buffer, i * beat, beat * 0.85, bass[(i // 4) % len(bass)], 0.075, "bass")
        percussion(buffer, i * beat, True)
        percussion(buffer, (i + 0.5) * beat, False)
    return buffer


def motif(notes, spacing, duration):
    buffer = [0.0] * int(duration * RATE)
    for i, note in enumerate(notes):
        tone(buffer, i * spacing, min(0.6, duration - i * spacing), note, 0.18)
    return buffer


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    tracks = {
        "LobbyMusic": loop(112, [72, 76, 79, 76, 74, 77, 81, 77, 76, 79, 84, 79, 74, 77, 79, 71], [48, 53, 57, 55]),
        "RoundMusic": loop(128, [74, 77, 81, 86, 81, 77, 79, 84, 74, 77, 81, 79, 72, 76, 79, 81], [50, 58, 48, 55]),
        "FinalMusic": loop(138, [74, 77, 81, 77, 74, 76, 79, 76, 72, 76, 79, 76, 73, 77, 81, 77], [50, 50, 48, 49]),
        "Click": motif([84], 0.1, 0.12),
        "Power": motif([69, 76, 81], 0.05, 0.4),
        "Warning": motif([70, 70, 74], 0.22, 0.9),
        "Qualified": motif([72, 76, 79, 84], 0.12, 0.9),
        "Eliminated": motif([69, 65, 60], 0.16, 0.8),
        "Victory": motif([72, 76, 79, 84, 79, 84, 88, 91], 0.2, 2.3),
        "Countdown": motif([79], 0.1, 0.22),
    }
    manifest = {"provenance": "Original algorithmic Royal Rush synthesis, no external recordings", "runtime": "Upload through your Roblox account and configure Config.Audio.Custom to enable custom audio", "assets": []}
    for name, samples in tracks.items():
        # Remove clicks at both ends and leave headroom; do not normalize to clipping.
        peak = max(abs(s) for s in samples)
        gain = min(1.0, 0.8 / peak) if peak else 1.0
        for j in range(min(240, len(samples))):
            samples[j] *= j / 240
            samples[-1-j] *= j / 240
        pcm = array("h", [round(max(-0.8, min(0.8, s * gain)) * 32767) for s in samples])
        path = OUT / f"{name}.wav"
        with wave.open(str(path), "wb") as wav:
            wav.setnchannels(1)
            wav.setsampwidth(2)
            wav.setframerate(RATE)
            wav.writeframes(pcm.tobytes())
        with wave.open(str(path), "rb") as wav:
            assert wav.getnchannels() == 1 and wav.getsampwidth() == 2 and wav.getframerate() == RATE
            assert wav.getnframes() == len(samples)
        manifest["assets"].append({"key": name, "file": path.name, "seconds": round(len(samples)/RATE, 3), "channels": 1, "sampleRate": RATE, "bytes": path.stat().st_size, "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "assetId": None})
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Generated and reopened {len(tracks)} original PCM WAV assets; no Roblox upload performed.")


if __name__ == "__main__":
    main()
