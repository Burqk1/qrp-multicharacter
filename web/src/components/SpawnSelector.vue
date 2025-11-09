<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { fetchNui } from '../utils/nuiEvents'

const props = defineProps({
  spawnLocations: {
    type: Array,
    default: () => []
  },
  lastLocation: {
    type: Object,
    default: null
  }
})

const selectedSpawn = ref(0)

const locations = computed(() => {
  const locs = [...props.spawnLocations]

  if (props.lastLocation) {
    locs.unshift({
      name: 'Last Location',
      icon: '🏠',
      coords: props.lastLocation,
      isLast: true
    })
  }

  return locs
})

const currentLocation = computed(() => {
  return locations.value[selectedSpawn.value]
})

const selectLocation = async (index) => {
  selectedSpawn.value = index

  await fetchNui('changeSpawnLocation', {
    coords: locations.value[index].coords
  })
}

const handleSpawn = async () => {
  const location = currentLocation.value
  if (!location) return

  await fetchNui('spawnPlayer', {
    coords: location.coords
  })
}

const handleKeydown = (event) => {
  if (event.key === 'ArrowLeft') {
    event.preventDefault()
    const newIndex = selectedSpawn.value > 0 ? selectedSpawn.value - 1 : locations.value.length - 1
    selectLocation(newIndex)
  } else if (event.key === 'ArrowRight') {
    event.preventDefault()
    const newIndex = selectedSpawn.value < locations.value.length - 1 ? selectedSpawn.value + 1 : 0
    selectLocation(newIndex)
  } else if (event.key === 'Enter') {
    event.preventDefault()
    handleSpawn()
  }
}

onMounted(() => {
  window.addEventListener('keydown', handleKeydown)

  if (locations.value.length > 0) {
    selectLocation(0)
  }
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})
</script>

<template>
  <div class="spawn-container">
    <div class="bottom-menu">
      <div class="menu-content">
        <div class="location-display">
          <button class="nav-arrow" @click="selectLocation(selectedSpawn > 0 ? selectedSpawn - 1 : locations.length - 1)">
            <span>&lt;</span>
          </button>

          <div class="location-center">
            <h2 class="location-title">{{ currentLocation?.name || 'SELECT LOCATION' }}</h2>
            <p v-if="currentLocation?.isLast" class="location-subtitle">Select Last Position</p>
            <p v-else class="location-subtitle">{{ currentLocation?.name || 'Mirror Park Blvd' }}</p>
          </div>

          <button class="nav-arrow" @click="selectLocation(selectedSpawn < locations.length - 1 ? selectedSpawn + 1 : 0)">
            <span>&gt;</span>
          </button>
        </div>

        <button class="btn-spawn" @click="handleSpawn">
          <span>SPAWN</span>
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.spawn-container {
  width: 100vw;
  height: 100vh;
  position: relative;
  overflow: hidden;
  background: transparent;
  font-family: 'Inter', 'Segoe UI', sans-serif;
  display: flex;
  align-items: flex-end;
  justify-content: center;
}

.bottom-menu {
  position: absolute;
  bottom: 60px;
  left: 50%;
  transform: translateX(-50%);
  width: auto;
  animation: slideInUp 0.5s ease;
  z-index: 10;
}

.menu-content {
  display: flex;
  flex-direction: column;
  gap: 20px;
  align-items: center;
}

.location-display {
  display: flex;
  align-items: center;
  gap: 40px;
}

.nav-arrow {
  width: 50px;
  height: 50px;
  background: rgba(0, 0, 0, 0.5);
  border: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 50%;
  cursor: pointer;
  transition: all 0.25s ease;
  display: flex;
  align-items: center;
  justify-content: center;
}

.nav-arrow span {
  font-size: 24px;
  font-weight: 700;
  color: rgba(255, 255, 255, 0.9);
}

.nav-arrow:hover {
  background: rgba(0, 0, 0, 0.7);
  border-color: rgba(255, 255, 255, 0.3);
  transform: scale(1.1);
}

.nav-arrow:active {
  transform: scale(0.95);
}

.location-center {
  text-align: center;
  min-width: 300px;
}

.location-title {
  font-size: 28px;
  font-weight: 700;
  color: #ffffff;
  margin: 0 0 8px 0;
  letter-spacing: 1px;
  text-transform: uppercase;
  text-shadow: 0 2px 8px rgba(0, 0, 0, 0.8);
}

.location-subtitle {
  font-size: 13px;
  color: rgba(255, 255, 255, 0.7);
  margin: 0;
  letter-spacing: 0.5px;
  text-shadow: 0 1px 4px rgba(0, 0, 0, 0.8);
}

.btn-spawn {
  min-width: 200px;
  padding: 14px 40px;
  background: rgba(74, 222, 128, 0.15);
  border: 2px solid rgba(74, 222, 128, 0.5);
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.25s ease;
}

.btn-spawn span {
  font-size: 14px;
  font-weight: 700;
  color: rgba(74, 222, 128, 1);
  letter-spacing: 2px;
  text-transform: uppercase;
  text-shadow: 0 0 10px rgba(74, 222, 128, 0.3);
}

.btn-spawn:hover {
  background: rgba(74, 222, 128, 0.25);
  border-color: rgba(74, 222, 128, 0.8);
  transform: translateY(-2px);
  box-shadow: 0 4px 20px rgba(74, 222, 128, 0.3);
}

.btn-spawn:active {
  transform: translateY(0);
}

@keyframes slideInUp {
  from {
    transform: translateX(-50%) translateY(100%);
    opacity: 0;
  }
  to {
    transform: translateX(-50%) translateY(0);
    opacity: 1;
  }
}
</style>
