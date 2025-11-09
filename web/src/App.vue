<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { fetchNui, isEnvBrowser } from './utils/nuiEvents'
import CharacterSelection from './components/CharacterSelection.vue'
import SpawnSelector from './components/SpawnSelector.vue'

const isVisible = ref(isEnvBrowser())
const showSpawnSelector = ref(false)
const characters = ref([])
const maxCharacters = ref(4)
const spawnLocations = ref([])
const lastLocation = ref(null)

const handleMessage = (event) => {
  const { action, data } = event.data

  switch (action) {
    case 'openUI':
      isVisible.value = true
      showSpawnSelector.value = false
      characters.value = data.characters || []
      maxCharacters.value = data.maxCharacters || 4
      break
    case 'closeUI':
      isVisible.value = false
      showSpawnSelector.value = false
      break
    case 'openSpawnSelector':
      isVisible.value = true
      showSpawnSelector.value = true
      spawnLocations.value = data.locations || []
      lastLocation.value = data.lastLocation || null
      break
  }
}

const handleKeydown = (event) => {
  if (event.key === 'Escape' && isVisible.value) {
    fetchNui('closeUI', {})
    isVisible.value = false
  }
}

onMounted(() => {
  window.addEventListener('message', handleMessage)
  window.addEventListener('keydown', handleKeydown)

  if (isEnvBrowser()) {
    characters.value = [
      {
        citizenid: '1',
        charinfo: JSON.stringify({
          firstname: 'John',
          lastname: 'Doe',
          birthdate: '1990-01-01',
          nationality: 'USA'
        }),
        money: JSON.stringify({
          bank: 5000,
          cash: 1000
        }),
        job: JSON.stringify({
          label: 'Police',
          grade: { name: 'Officer' }
        })
      }
    ]
  }
})

onUnmounted(() => {
  window.removeEventListener('message', handleMessage)
  window.removeEventListener('keydown', handleKeydown)
})
</script>

<template>
  <div v-if="isVisible" class="w-screen h-screen overflow-hidden">
    <Transition name="fade" mode="out-in">
      <SpawnSelector
        v-if="showSpawnSelector"
        :spawnLocations="spawnLocations"
        :lastLocation="lastLocation"
        key="spawn"
      />
      <CharacterSelection
        v-else
        :characters="characters"
        :maxCharacters="maxCharacters"
        key="character"
      />
    </Transition>
  </div>
</template>

<style>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
