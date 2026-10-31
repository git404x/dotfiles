let activeStream = null;
let audioContext = null;
let analyser = null;
let animId = null;
let peakHold = 0;
let peakHoldTimer = 0;
let frameCount = 0;
let lastFpsTime = performance.now();
let currentFps = 0;

const videoEl = document.getElementById('videoPreview');
const cameraSelect = document.getElementById('cameraSelect');
const micSelect = document.getElementById('micSelect');
const toggleBtn = document.getElementById('toggleStreamBtn');
const streamIndicator = document.getElementById('streamIndicator');
const streamStatusText = document.getElementById('streamStatusText');
const statRes = document.getElementById('statResolution');
const statFps = document.getElementById('statFps');
const vuFill = document.getElementById('vuFill');
const vuPeak = document.getElementById('vuPeak');
const rmsDbText = document.getElementById('rmsDb');
const peakDbText = document.getElementById('peakDb');
const canvas = document.getElementById('scopeCanvas');
const ctx = canvas.getContext('2d');
const cliOutput = document.getElementById('cliOutput');

async function enumerateDevices() {
  try {
    const devices = await navigator.mediaDevices.enumerateDevices();
    cameraSelect.innerHTML = '';
    micSelect.innerHTML = '';

    devices.forEach(dev => {
      if (dev.kind === 'videoinput') {
        const opt = document.createElement('option');
        opt.value = dev.deviceId;
        opt.text = dev.label || `Camera ${cameraSelect.length + 1}`;
        if (dev.label.toLowerCase().includes('hd webcam') || dev.label.toLowerCase().includes('loopback')) {
          opt.selected = true;
        }
        cameraSelect.appendChild(opt);
      } else if (dev.kind === 'audioinput') {
        const opt = document.createElement('option');
        opt.value = dev.deviceId;
        opt.text = dev.label || `Microphone ${micSelect.length + 1}`;
        if (dev.label.toLowerCase().includes('virtual') || dev.label.toLowerCase().includes('vcam')) {
          opt.selected = true;
        }
        micSelect.appendChild(opt);
      }
    });

    if (cameraSelect.options.length === 0) {
      cameraSelect.innerHTML = '<option value="">No cameras detected</option>';
    }
    if (micSelect.options.length === 0) {
      micSelect.innerHTML = '<option value="">No microphones detected</option>';
    }
  } catch (err) {
    console.error('enumerateDevices error:', err);
  }
}

async function startStream() {
  stopStream();

  const videoConstraints = cameraSelect.value ? {
    deviceId: { exact: cameraSelect.value },
    width: { ideal: 1280 },
    height: { ideal: 720 },
    frameRate: { ideal: 30 }
  } : { width: 1280, height: 720, frameRate: 30 };

  const audioConstraints = micSelect.value ? {
    deviceId: { exact: micSelect.value },
    echoCancellation: false,
    noiseSuppression: false,
    autoGainControl: false
  } : true;

  try {
    activeStream = await navigator.mediaDevices.getUserMedia({
      video: videoConstraints,
      audio: audioConstraints
    });

    videoEl.srcObject = activeStream;
    await enumerateDevices();
    setupAudioAnalyser(activeStream);

    toggleBtn.textContent = 'Stop Capture';
    toggleBtn.className = 'danger';
    streamIndicator.style.display = 'inline-block';
    streamStatusText.textContent = 'ACTIVE STREAM';
    streamStatusText.style.color = 'var(--success)';

    startFpsTracker();
  } catch (err) {
    alert('Failed to start stream: ' + err.message);
    console.error('getUserMedia error:', err);
  }
}

function stopStream() {
  if (activeStream) {
    activeStream.getTracks().forEach(track => track.stop());
    activeStream = null;
  }
  if (audioContext && audioContext.state !== 'closed') {
    audioContext.close();
    audioContext = null;
  }
  if (animId) {
    cancelAnimationFrame(animId);
    animId = null;
  }

  videoEl.srcObject = null;
  toggleBtn.textContent = 'Start Capture';
  toggleBtn.className = 'primary';
  streamIndicator.style.display = 'none';
  streamStatusText.textContent = 'STANDBY';
  streamStatusText.style.color = 'var(--text-muted)';
  statRes.textContent = '-- x --';
  statFps.textContent = '--';
  vuFill.style.width = '0%';
  vuPeak.style.left = '0%';
  rmsDbText.textContent = '-inf dB';
  peakDbText.textContent = '-inf dB';

  ctx.fillStyle = '#0a0c12';
  ctx.fillRect(0, 0, canvas.width, canvas.height);
}

function toggleStream() {
  if (activeStream) stopStream();
  else startStream();
}

function setupAudioAnalyser(stream) {
  audioContext = new (window.AudioContext || window.webkitAudioContext)({ sampleRate: 48000 });
  const source = audioContext.createMediaStreamSource(stream);
  analyser = audioContext.createAnalyser();
  analyser.fftSize = 1024;
  analyser.smoothingTimeConstant = 0.3;
  source.connect(analyser);

  const bufferLength = analyser.frequencyBinCount;
  const timeData = new Uint8Array(bufferLength);

  function drawScope() {
    if (!analyser) return;
    animId = requestAnimationFrame(drawScope);

    analyser.getByteTimeDomainData(timeData);

    let sum = 0;
    let peak = 0;
    for (let i = 0; i < bufferLength; i++) {
      const val = (timeData[i] - 128) / 128;
      const abs = Math.abs(val);
      if (abs > peak) peak = abs;
      sum += val * val;
    }

    const rms = Math.sqrt(sum / bufferLength);
    const rmsDb = rms > 0.00001 ? 20 * Math.log10(rms) : -100;
    const peakDb = peak > 0.00001 ? 20 * Math.log10(peak) : -100;

    const vuPercent = Math.max(0, Math.min(100, ((rmsDb + 60) / 60) * 100));
    vuFill.style.width = vuPercent + '%';

    if (peakDb > peakHold || performance.now() - peakHoldTimer > 1000) {
      peakHold = peakDb;
      peakHoldTimer = performance.now();
    }
    const peakPercent = Math.max(0, Math.min(100, ((peakHold + 60) / 60) * 100));
    vuPeak.style.left = peakPercent + '%';

    rmsDbText.textContent = `${rmsDb.toFixed(1)} dB`;
    peakDbText.textContent = `${peakDb.toFixed(1)} dB`;

    ctx.fillStyle = '#0a0c12';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.lineWidth = 2;
    ctx.strokeStyle = '#3b82f6';
    ctx.beginPath();

    const sliceWidth = canvas.width / bufferLength;
    let x = 0;
    for (let i = 0; i < bufferLength; i++) {
      const v = timeData[i] / 128.0;
      const y = (v * canvas.height) / 2;
      if (i === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
      x += sliceWidth;
    }
    ctx.stroke();
  }

  drawScope();
}

function startFpsTracker() {
  function checkStats() {
    if (!activeStream) return;

    if (videoEl.videoWidth && videoEl.videoHeight) {
      statRes.textContent = `${videoEl.videoWidth} x ${videoEl.videoHeight}`;
    }

    frameCount++;
    const now = performance.now();
    const delta = now - lastFpsTime;
    if (delta >= 1000) {
      currentFps = Math.round((frameCount * 1000) / delta);
      statFps.textContent = currentFps;
      frameCount = 0;
      lastFpsTime = now;
    }

    requestAnimationFrame(checkStats);
  }
  requestAnimationFrame(checkStats);
}

async function runCli(command) {
  cliOutput.textContent = `Running: vcam ${command}...`;
  try {
    const resp = await fetch('/api/cli', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ cmd: command })
    });
    const text = await resp.text();
    try {
      const data = JSON.parse(text);
      cliOutput.textContent = data.ok ? `Success: ${data.stdout || command}` : `Error: ${data.err || data.stderr}`;
    } catch {
      cliOutput.textContent = `Response: ${text.substring(0, 100)}`;
    }
  } catch (err) {
    cliOutput.textContent = `Server communication error: ${err.message}`;
  }
}

async function shutdownServer() {
  if (confirm('Stop the diagnostic web server?')) {
    try {
      await fetch('/api/quit', { method: 'POST' });
    } catch {}
    stopStream();
    document.body.innerHTML = '<div style="padding: 40px; text-align: center; color: #9ca3af; font-family: monospace;"><h3>Test bench server stopped.</h3><p style="margin-top: 10px;">You can close this tab.</p></div>';
  }
}

navigator.mediaDevices.addEventListener('devicechange', enumerateDevices);
enumerateDevices();
