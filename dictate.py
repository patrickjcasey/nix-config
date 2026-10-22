"""Live dictation: type each phrase into the focused window as soon as you pause.

Running `dictate` starts recording; running it again stops it. Audio is split
on short pauses and each phrase is sent to the local whisper-server, then typed
with xdotool. See dictation.nix.
"""

import array
import io
import json
import math
import os
import queue
import re
import signal
import subprocess
import sys
import threading
import time
import urllib.request
import uuid
import wave

URL = os.environ.get("DICTATE_URL", "http://127.0.0.1:8178/inference")
RATE = 16000
FRAME = 480  # 30 ms of 16-bit mono samples
FRAME_MS = 30

PAUSE_MS = int(os.environ.get("DICTATE_PAUSE_MS", "600"))  # silence that ends a phrase
MIN_SPEECH_MS = 250  # shorter blips are ignored (coughs, clicks)
MAX_PHRASE_S = 25  # force a cut so whisper's 30 s window is never exceeded
PREROLL_MS = 300  # audio kept from before speech starts
MIN_LEVEL = float(os.environ.get("DICTATE_MIN_LEVEL", "300"))  # absolute RMS floor

STATE = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "dictate")
PIDFILE = os.path.join(STATE, "pid")


def log(msg):
    print(f"{time.strftime('%H:%M:%S')} {msg}", file=sys.stderr, flush=True)


def bar(n):
    """Polybar indicator: 0 = idle, 1 = recording, 2 = finishing."""
    subprocess.run(["polybar-msg", "action", "dictate", "hook", str(n)],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def toggle_off():
    """If a recording is running, ask it to stop. Returns True if one was."""
    try:
        with open(PIDFILE) as f:
            pid = int(f.read())
        os.kill(pid, signal.SIGINT)
        return True
    except (FileNotFoundError, ValueError, ProcessLookupError):
        return False


def rms(frame):
    return math.sqrt(sum(s * s for s in frame) / len(frame))


def to_wav(samples):
    buf = io.BytesIO()
    with wave.open(buf, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(samples.tobytes())
    return buf.getvalue()


def transcribe(wav, prompt):
    boundary = uuid.uuid4().hex
    fields = {"response_format": "json", "temperature": "0", "prompt": prompt}
    body = b""
    for k, v in fields.items():
        body += (f"--{boundary}\r\nContent-Disposition: form-data; name=\"{k}\"\r\n\r\n{v}\r\n").encode()
    body += (f"--{boundary}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"a.wav\"\r\n"
             "Content-Type: audio/wav\r\n\r\n").encode() + wav + f"\r\n--{boundary}--\r\n".encode()
    req = urllib.request.Request(URL, data=body, headers={
        "Content-Type": f"multipart/form-data; boundary={boundary}"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r).get("text", "")


def clean(text):
    # drop non-speech tags like [BLANK_AUDIO] or (keyboard clicking)
    text = re.sub(r"\[[^]]*\]|\([^)]*\)|\*[^*]*\*", "", text)
    return re.sub(r"\s+", " ", text).strip()


def typist(phrases):
    """Transcribe and type phrases in order, one at a time."""
    typed = ""
    while (samples := phrases.get()) is not None:
        try:
            text = clean(transcribe(to_wav(samples), typed[-200:]))
        except Exception as e:
            log(f"transcription failed: {e}")
            continue
        log(f"heard {len(samples) / RATE:.1f}s -> {text!r}")
        if not text:
            continue
        if typed:
            text = " " + text
        subprocess.run(["xdotool", "type", "--clearmodifiers", "--delay", "2", "--", text])
        typed += text


def main():
    if toggle_off():
        return

    os.makedirs(STATE, exist_ok=True)
    with open(PIDFILE, "w") as f:
        f.write(str(os.getpid()))

    rec = subprocess.Popen(
        ["pw-record", "--rate", str(RATE), "--channels", "1", "--format", "s16", "--raw", "-"],
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)

    stopping = threading.Event()

    def stop(*_):
        stopping.set()
        rec.terminate()

    signal.signal(signal.SIGINT, stop)
    signal.signal(signal.SIGTERM, stop)

    phrases = queue.Queue()
    worker = threading.Thread(target=typist, args=(phrases,))
    worker.start()
    bar(1)

    noise = MIN_LEVEL / 3  # running estimate of the background level
    preroll = []
    phrase = None  # array of samples while inside a phrase
    speech_ms = silence_ms = 0
    peak = 0.0
    log("recording")

    def flush():
        nonlocal phrase, speech_ms, silence_ms
        if phrase is not None and speech_ms >= MIN_SPEECH_MS:
            phrases.put(phrase)
        phrase = None
        speech_ms = silence_ms = 0

    try:
        while not stopping.is_set():
            data = rec.stdout.read(FRAME * 2)
            if len(data) < FRAME * 2:
                break
            frame = array.array("h", data)
            level = rms(frame)
            peak = max(peak, level)
            voiced = level > max(MIN_LEVEL, noise * 3)
            if not voiced:
                noise = 0.95 * noise + 0.05 * level

            if phrase is None:
                preroll.append(frame)
                del preroll[:-PREROLL_MS // FRAME_MS]
                if voiced:
                    phrase = array.array("h")
                    for f in preroll:
                        phrase.extend(f)
                    preroll.clear()
                    speech_ms = FRAME_MS
                continue

            phrase.extend(frame)
            if voiced:
                speech_ms += FRAME_MS
                silence_ms = 0
            else:
                silence_ms += FRAME_MS
            if silence_ms >= PAUSE_MS or len(phrase) >= MAX_PHRASE_S * RATE:
                flush()
    finally:
        rec.terminate()
        rec.wait()
        try:
            os.remove(PIDFILE)
        except FileNotFoundError:
            pass
        log(f"stopped: peak level {peak:.0f}, speech threshold {max(MIN_LEVEL, noise * 3):.0f}")
        bar(2)
        flush()
        phrases.put(None)
        worker.join()
        bar(0)


if __name__ == "__main__":
    main()
