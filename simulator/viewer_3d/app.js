import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

// Feature-detect native HTML <input type="checkbox" switch> (modern-web-guidance: switch)
if (!('switch' in HTMLInputElement.prototype)) {
  document.documentElement.classList.add('no-native-switch');
}

// --- 1. Three.js Scene, Camera & Renderer ---
const container = document.getElementById('canvas-container');
const scene = new THREE.Scene();
scene.background = new THREE.Color(0xc8e6f5);
scene.fog = new THREE.Fog(0xc8e6f5, 26, 68);

const isPortrait = () => window.innerWidth < window.innerHeight;

const camera = new THREE.PerspectiveCamera(
  isPortrait() ? 54 : 45,
  window.innerWidth / window.innerHeight,
  0.1,
  150
);
if (isPortrait()) {
  camera.position.set(16.5, 10.5, 18.5);
} else {
  camera.position.set(12.5, 7.6, 13.8);
}

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.1;
container.appendChild(renderer.domElement);

const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;
controls.dampingFactor = 0.06;
controls.maxPolarAngle = Math.PI / 2 - 0.03;
controls.minDistance = 3.0;
controls.maxDistance = 32.0;
controls.target.set(0, 1.5, 0);

// --- 2. Environment Lighting ---
const hemiLight = new THREE.HemisphereLight(0xdff5ff, 0x2f5a2c, 0.95);
scene.add(hemiLight);

const sunLight = new THREE.DirectionalLight(0xfff7e6, 1.9);
sunLight.position.set(14, 22, 12);
sunLight.castShadow = true;
sunLight.shadow.mapSize.set(2048, 2048);
sunLight.shadow.camera.near = 2;
sunLight.shadow.camera.far = 55;
sunLight.shadow.camera.left = -14;
sunLight.shadow.camera.right = 14;
sunLight.shadow.camera.top = 14;
sunLight.shadow.camera.bottom = -14;
scene.add(sunLight);

// Dynamic actuator lights (toggled live by simulator state)
const growPointLights = [];
const bedCoords = [
  [-2.65, 2.45, 3.3],
  [-2.65, 2.45, -3.3],
  [2.65, 2.45, 3.3],
  [2.65, 2.45, -3.3],
];
for (const [x, y, z] of bedCoords) {
  const pl = new THREE.PointLight(0xd54bff, 0, 9.5, 1.4);
  pl.position.set(x, y, z);
  scene.add(pl);
  growPointLights.push(pl);
}

const heaterLights = [
  new THREE.PointLight(0xff5a1f, 0, 11.0, 1.5),
  new THREE.PointLight(0xff5a1f, 0, 11.0, 1.5),
];
heaterLights[0].position.set(0, 2.5, 5.2);
heaterLights[1].position.set(0, 2.5, -5.2);
heaterLights.forEach((l) => scene.add(l));

const overheatLight = new THREE.PointLight(0xff1744, 0, 18.0, 1.2);
overheatLight.position.set(0, 3.6, 0);
scene.add(overheatLight);

// --- 3. Interactive Object Registries (from Blender GLB) ---
const interactive = {
  ventsLeft: [],
  ventsRight: [],
  fanBlades: [],
  growEmitters: [],
  heaterCoils: [],
  soilBeds: [],
};

// --- 4. Animated Drip Irrigation Water Droplets ---
const DROPLET_COUNT = 240;
const dropletPositions = new Float32Array(DROPLET_COUNT * 3);
const dropletSpeeds = new Float32Array(DROPLET_COUNT);

function resetDroplet(i) {
  const bed = bedCoords[i % bedCoords.length];
  dropletPositions[i * 3 + 0] = bed[0] + (Math.random() - 0.5) * 1.4;
  dropletPositions[i * 3 + 1] = 0.55 + Math.random() * 0.65;
  dropletPositions[i * 3 + 2] = bed[2] + (Math.random() - 0.5) * 4.8;
  dropletSpeeds[i] = 0.9 + Math.random() * 0.9;
}
for (let i = 0; i < DROPLET_COUNT; i++) resetDroplet(i);

const dropletGeo = new THREE.BufferGeometry();
dropletGeo.setAttribute('position', new THREE.BufferAttribute(dropletPositions, 3));
const dropletMat = new THREE.PointsMaterial({
  color: 0x38bdf8,
  size: 0.14,
  transparent: true,
  opacity: 0.85,
});
const irrigationParticles = new THREE.Points(dropletGeo, dropletMat);
irrigationParticles.visible = false;
scene.add(irrigationParticles);

// --- 5. Load Blender GLB Greenhouse ---
const loader = new GLTFLoader();
loader.load(
  './assets/greenhouse.glb',
  (gltf) => {
    const root = gltf.scene;
    root.traverse((obj) => {
      if (obj.isMesh) {
        obj.castShadow = true;
        obj.receiveShadow = true;

        // Make greenhouse glass crystal-clear translucent
        if (obj.name.startsWith('Greenhouse_Glass') && obj.material) {
          obj.material = obj.material.clone();
          obj.material.transparent = true;
          obj.material.opacity = 0.16;
          obj.material.depthWrite = false;
          obj.castShadow = false;
        }
        if (obj.name.startsWith('VentWindow_') && obj.material) {
          obj.material = obj.material.clone();
          obj.material.transparent = true;
          obj.material.opacity = 0.34;
          obj.material.depthWrite = false;
        }
      }

      if (obj.name.startsWith('VentWindow_Left')) {
        obj.userData.baseRotZ = obj.rotation.z;
        interactive.ventsLeft.push(obj);
      } else if (obj.name.startsWith('VentWindow_Right')) {
        obj.userData.baseRotZ = obj.rotation.z;
        interactive.ventsRight.push(obj);
      } else if (obj.name.startsWith('ExhaustFan_Blades')) {
        interactive.fanBlades.push(obj);
      } else if (obj.name.startsWith('GrowLight_Emitter')) {
        if (obj.material) obj.material = obj.material.clone();
        interactive.growEmitters.push(obj);
      } else if (obj.name.startsWith('Heater_Coil')) {
        if (obj.material) obj.material = obj.material.clone();
        interactive.heaterCoils.push(obj);
      } else if (obj.name.startsWith('SoilBed_')) {
        if (obj.material) obj.material = obj.material.clone();
        interactive.soilBeds.push(obj);
      }
    });

    scene.add(root);
    document.getElementById('event-ticker').textContent =
      '✅ 3D-модель Blender загружена (greenhouse.glb)';
  },
  undefined,
  (err) => {
    console.error('Failed to load greenhouse.glb:', err);
    document.getElementById('event-ticker').textContent =
      '⚠️ Не удалось загрузить greenhouse.glb — проверьте сервер';
  }
);

// --- 6. Camera Presets ---
function getCameraPreset(name) {
  const portrait = isPortrait();
  const presets = {
    overview: {
      pos: portrait ? new THREE.Vector3(16.5, 10.5, 18.5) : new THREE.Vector3(12.5, 7.6, 13.8),
      target: new THREE.Vector3(0, 1.5, 0),
    },
    inside: { pos: new THREE.Vector3(0.0, 1.75, 5.6), target: new THREE.Vector3(0, 1.4, -2.5) },
    roof: { pos: new THREE.Vector3(6.8, 6.4, 5.2), target: new THREE.Vector3(0, 4.1, 0) },
    top: {
      pos: portrait ? new THREE.Vector3(0.0, 26.0, 0.1) : new THREE.Vector3(0.0, 19.5, 0.1),
      target: new THREE.Vector3(0, 0, 0),
    },
  };
  return presets[name];
}
let activeCamLerp = null;

document.querySelectorAll('.btn-cam').forEach((btn) => {
  btn.addEventListener('click', () => {
    const preset = getCameraPreset(btn.dataset.cam);
    if (!preset) return;
    document.querySelectorAll('.btn-cam').forEach((b) => b.classList.remove('active'));
    btn.classList.add('active');
    activeCamLerp = { pos: preset.pos.clone(), target: preset.target.clone(), t: 0 };
  });
});

// --- 6b. Mobile Bottom Sheet Navigation ---
const panelTelemetry = document.getElementById('panel-telemetry');
const panelControls = document.getElementById('panel-controls');
const dockButtons = document.querySelectorAll('.dock-btn');
let activeMobileSheet = 'none';

function setMobileSheet(sheetName) {
  activeMobileSheet = sheetName;
  const openTelemetry = sheetName === 'telemetry';
  const openControls = sheetName === 'controls';

  panelTelemetry?.classList.toggle('sheet-open', openTelemetry);
  panelControls?.classList.toggle('sheet-open', openControls);
  document.body.classList.toggle('sheet-active', openTelemetry || openControls);

  dockButtons.forEach((btn) => {
    const isActive = btn.dataset.sheet === sheetName;
    btn.classList.toggle('active', isActive);
    btn.setAttribute('aria-pressed', String(isActive));
  });
}

dockButtons.forEach((btn) => {
  btn.addEventListener('click', () => {
    const target = btn.dataset.sheet;
    if (target === activeMobileSheet && target !== 'none') {
      setMobileSheet('none');
    } else {
      setMobileSheet(target);
    }
  });
});

document.querySelectorAll('[data-close-sheet]').forEach((btn) => {
  btn.addEventListener('click', () => setMobileSheet('none'));
});

window.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && activeMobileSheet !== 'none') {
    setMobileSheet('none');
  }
});

// --- 7. Simulator State & HUD Synchronization ---
let simState = {
  telemetry: { air_temp: 24.2, air_humidity: 62.0, soil_moisture: 45.5, light_level: 12400, is_overheated: false, is_drought: false, is_optimal: true },
  actuators: { irrigation: false, ventilation: false, heater: false, lighting: false, last_latency_ms: 450 },
  energy: { monthly_saved_tenge: 48200, power_kw: 0, tariff_kzt: 28.5, is_night_tariff: false },
  water: { monthly_saved_liters: 0, monthly_saved_kzt: 0 },
  weather: { outdoor_temp_c: 12.0 },
  status: { online: true, stale_seconds: 0, last_event: 'Подключение...' },
};

function renderHud(state) {
  simState = state;
  const { telemetry, actuators, energy, water, weather, status } = state;

  document.getElementById('val-temp').textContent = `${telemetry.air_temp.toFixed(1)} °C`;
  document.getElementById('val-hum').textContent = `${telemetry.air_humidity.toFixed(1)} %`;
  document.getElementById('val-soil').textContent = `${telemetry.soil_moisture.toFixed(1)} %`;
  document.getElementById('val-light').textContent = `${(telemetry.light_level / 1000).toFixed(1)} kLux`;

  document.getElementById('val-tariff').textContent = energy.is_night_tariff
    ? `Ночной тариф: ${energy.tariff_kzt.toFixed(2)} ₸`
    : `Дневной тариф: ${energy.tariff_kzt.toFixed(2)} ₸`;
  document.getElementById('val-power').textContent = `${energy.power_kw.toFixed(1)} kW`;
  document.getElementById('val-water').textContent = `${Math.round(water.monthly_saved_liters).toLocaleString('ru-RU')} л`;
  document.getElementById('val-outdoor').textContent = `${weather.outdoor_temp_c.toFixed(1)} °C`;

  document.getElementById('monthly-savings').textContent =
    `${Math.round(energy.monthly_saved_tenge).toLocaleString('ru-RU')} ₸`;
  document.getElementById('latency-value').textContent =
    `${(actuators.last_latency_ms / 1000).toFixed(2)} s`;
  document.getElementById('event-ticker').textContent = status.last_event;

  // Card alert highlights
  document.getElementById('card-temp').classList.toggle('alert', telemetry.is_overheated);
  document.getElementById('card-soil').classList.toggle('alert', telemetry.is_drought);

  // Switches
  for (const name of ['irrigation', 'ventilation', 'heater', 'lighting']) {
    const el = document.getElementById(`toggle-${name}`);
    if (el && el.checked !== Boolean(actuators[name])) {
      el.checked = Boolean(actuators[name]);
    }
  }

  // Health & M8 offline banner
  const dot = document.getElementById('connection-dot');
  const pill = document.getElementById('health-pill');
  const banner = document.getElementById('alert-banner');
  const bannerText = document.getElementById('alert-banner-text');

  dot.classList.toggle('offline', !status.online);

  if (!status.online) {
    pill.textContent = 'Офлайн (M8)';
    pill.className = 'status-pill critical';
    banner.classList.remove('hidden');
    bannerText.textContent =
      `⚠️ Симулятор отключён (${status.stale_seconds}s). Отображаются кэшированные показания. 3D-сцена работает штатно.`;
  } else if (telemetry.is_overheated) {
    pill.textContent = 'Перегрев!';
    pill.className = 'status-pill critical';
    banner.classList.remove('hidden');
    bannerText.textContent =
      `🔥 Критический перегрев (${telemetry.air_temp.toFixed(1)}°C)! Включите вентиляцию для охлаждения.`;
  } else if (telemetry.is_drought) {
    pill.textContent = 'Засуха';
    pill.className = 'status-pill warning';
    banner.classList.remove('hidden');
    bannerText.textContent =
      `💧 Дефицит влаги в почве (${telemetry.soil_moisture.toFixed(1)}%). Включите капельный полив.`;
  } else {
    pill.textContent = 'Оптимум';
    pill.className = 'status-pill optimal';
    banner.classList.add('hidden');
  }
}

async function fetchState() {
  try {
    const res = await fetch('/api/state', { cache: 'no-store' });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    renderHud(data);
  } catch {
    renderHud({
      ...simState,
      status: {
        ...simState.status,
        online: false,
        stale_seconds: 45,
        last_event: 'Нет связи с Python-сервером — кэшированный режим (M8)',
      },
    });
  }
}

// Wire actuator switches
document.querySelectorAll('input[data-actuator]').forEach((input) => {
  input.addEventListener('change', async () => {
    const name = input.dataset.actuator;
    const value = input.checked;
    try {
      const res = await fetch('/api/actuator', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, value }),
      });
      if (res.ok) renderHud(await res.json());
    } catch {
      simState.actuators[name] = value;
      renderHud(simState);
    }
  });
});

// Wire Emergency Stop
document.getElementById('btn-emergency').addEventListener('click', async () => {
  try {
    const res = await fetch('/api/actuator', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'emergency_stop', value: false }),
    });
    if (res.ok) renderHud(await res.json());
  } catch {
    simState.actuators = { ...simState.actuators, irrigation: false, ventilation: false, heater: false, lighting: false };
    renderHud(simState);
  }
});

// Wire Stress Tests
document.querySelectorAll('button[data-stress]').forEach((btn) => {
  btn.addEventListener('click', async () => {
    const scenario = btn.dataset.stress;
    try {
      const res = await fetch('/api/stress', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ scenario }),
      });
      if (res.ok) renderHud(await res.json());
    } catch {
      // ignore if offline
    }
  });
});

// Poll simulator every 1.2s
fetchState();
setInterval(fetchState, 1200);

// --- 8. Main 60fps Animation Loop (3D Actuator Effects) ---
const clock = new THREE.Clock();
let ventOpenFactor = 0;

function animate() {
  requestAnimationFrame(animate);
  const dt = Math.min(clock.getDelta(), 0.1);
  const elapsed = clock.getElapsedTime();
  const { actuators, telemetry } = simState;

  // Smooth camera preset transition
  if (activeCamLerp) {
    activeCamLerp.t = Math.min(1, activeCamLerp.t + dt * 2.8);
    camera.position.lerp(activeCamLerp.pos, 0.12);
    controls.target.lerp(activeCamLerp.target, 0.12);
    if (activeCamLerp.t >= 1) activeCamLerp = null;
  }

  // 1) Ventilation: open roof transoms + spin exhaust fans
  const targetVent = actuators.ventilation ? 1 : 0;
  ventOpenFactor += (targetVent - ventOpenFactor) * Math.min(1, dt * 4.0);
  const openAngle = ventOpenFactor * 0.52; // ~30 deg upward
  interactive.ventsLeft.forEach((v) => {
    v.rotation.z = (v.userData.baseRotZ ?? 0) - openAngle;
  });
  interactive.ventsRight.forEach((v) => {
    v.rotation.z = (v.userData.baseRotZ ?? 0) + openAngle;
  });
  if (actuators.ventilation) {
    interactive.fanBlades.forEach((fb) => {
      fb.rotation.z += dt * 11.0;
    });
  }

  // 2) Grow Lighting: magenta-violet emissive + point lights
  const targetGrow = actuators.lighting ? 3.2 : 0.05;
  interactive.growEmitters.forEach((em) => {
    if (em.material && 'emissiveIntensity' in em.material) {
      em.material.emissiveIntensity += (targetGrow - em.material.emissiveIntensity) * 0.15;
    }
  });
  const targetGrowLight = actuators.lighting ? 12.0 : 0.0;
  growPointLights.forEach((pl) => {
    pl.intensity += (targetGrowLight - pl.intensity) * 0.15;
  });

  // 3) Heater: glowing orange coils + warm lights
  const targetHeat = actuators.heater ? 3.5 : 0.04;
  interactive.heaterCoils.forEach((coil) => {
    if (coil.material && 'emissiveIntensity' in coil.material) {
      coil.material.emissiveIntensity += (targetHeat - coil.material.emissiveIntensity) * 0.15;
    }
  });
  const targetHeatLight = actuators.heater ? 14.0 : 0.0;
  heaterLights.forEach((hl) => {
    hl.intensity += (targetHeatLight - hl.intensity) * 0.15;
  });

  // 4) Irrigation: animated water droplets + wet soil color
  irrigationParticles.visible = Boolean(actuators.irrigation);
  if (actuators.irrigation) {
    const posAttr = dropletGeo.getAttribute('position');
    for (let i = 0; i < DROPLET_COUNT; i++) {
      let y = posAttr.getY(i) - dropletSpeeds[i] * dt;
      if (y < 0.45) {
        resetDroplet(i);
        posAttr.setXYZ(
          i,
          dropletPositions[i * 3],
          dropletPositions[i * 3 + 1],
          dropletPositions[i * 3 + 2]
        );
      } else {
        posAttr.setY(i, y);
      }
    }
    posAttr.needsUpdate = true;
  }
  const wetColor = new THREE.Color(actuators.irrigation || telemetry.soil_moisture > 50 ? 0x24160c : 0x4a3220);
  interactive.soilBeds.forEach((bed) => {
    if (bed.material && bed.material.color) {
      bed.material.color.lerp(wetColor, 0.06);
      bed.material.roughness = actuators.irrigation ? 0.55 : 0.94;
    }
  });

  // 5) Overheat thermal pulse (> 28°C / 30°C)
  if (telemetry.is_overheated) {
    overheatLight.intensity = 10 + Math.sin(elapsed * 5.0) * 6;
  } else {
    overheatLight.intensity *= 0.85;
  }

  // 6) Dynamic ambient daylight from light_level
  const luxFactor = Math.max(0.35, Math.min(1.2, telemetry.light_level / 14000));
  sunLight.intensity = 1.6 * luxFactor;

  controls.update();
  renderer.render(scene, camera);
}
animate();

window.addEventListener('resize', () => {
  camera.fov = isPortrait() ? 54 : 45;
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
  if (window.innerWidth > 900 && activeMobileSheet !== 'none') {
    setMobileSheet('none');
  }
});
