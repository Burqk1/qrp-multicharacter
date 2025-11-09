<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { fetchNui } from '../utils/nuiEvents'

const props = defineProps({
  characters: {
    type: Array,
    default: () => []
  },
  maxCharacters: {
    type: Number,
    default: 4
  }
})

const selectedSlot = ref(-1) // Hiçbir karakter başlangıçta seçili değil
const showCreation = ref(false)
const showNationalityDropdown = ref(false)
const isTransitioning = ref(false)

const formData = ref({
  firstname: '',
  lastname: '',
  birthdate: '',
  nationality: 'USA',
  gender: 0
})

const genderOptions = [
  { label: 'Male', value: 0 },
  { label: 'Female', value: 1 }
]

const nationalityOptions = [
  'USA', 'UK', 'Germany', 'France', 'Italy', 'Spain',
  'Turkey', 'Russia', 'China', 'Japan', 'Brazil', 'Mexico'
]

const isFormValid = computed(() => {
  return formData.value.firstname.trim() !== '' &&
         formData.value.lastname.trim() !== '' &&
         formData.value.birthdate !== '' &&
         formData.value.nationality !== ''
})

const slots = computed(() => {
  const result = []
  for (let i = 0; i < props.maxCharacters; i++) {
    const char = props.characters[i]
    result.push({
      index: i,
      character: char || null,
      isEmpty: !char
    })
  }
  return result
})

const currentCharacter = computed(() => {
  return slots.value[selectedSlot.value]
})

const charInfo = computed(() => {
  if (!currentCharacter.value?.character?.charinfo) return null
  try {
    return JSON.parse(currentCharacter.value.character.charinfo)
  } catch {
    return null
  }
})

const job = computed(() => {
  if (!currentCharacter.value?.character?.job) return null
  try {
    return JSON.parse(currentCharacter.value.character.job)
  } catch {
    return null
  }
})

const money = computed(() => {
  if (!currentCharacter.value?.character?.money) return null
  try {
    return JSON.parse(currentCharacter.value.character.money)
  } catch {
    return null
  }
})

const phoneNumber = computed(() => {
  if (!charInfo.value?.phone) return 'Not Assigned'
  return charInfo.value.phone
})

const fullName = computed(() => {
  if (!charInfo.value) return null
  return `${charInfo.value.firstname} ${charInfo.value.lastname}`.toUpperCase()
})

const formatMoney = (amount) => {
  if (!amount && amount !== 0) return '$0'
  return '$' + amount.toLocaleString('en-US')
}

const selectSlot = async (index) => {
  if (isTransitioning.value) return

  isTransitioning.value = true

  selectedSlot.value = index
  const slot = slots.value[index]

  if (slot.isEmpty) {
    showCreation.value = true
    await fetchNui('changeSlot', { citizenid: null })
    isTransitioning.value = false
  } else {
    showCreation.value = false
    await fetchNui('changeSlot', { citizenid: slot.character.citizenid })

    // Smooth transition için kısa bir bekleme
    setTimeout(() => {
      isTransitioning.value = false
    }, 400)
  }
}

const handlePlay = async () => {
  const slot = currentCharacter.value
  if (slot.isEmpty) {
    // Form submit edilecek, bu fonksiyon çağrılmamalı
    return
  } else {
    await fetchNui('selectCharacter', { citizenid: slot.character.citizenid })
  }
}

const handleCreateCharacter = async () => {
  if (!isFormValid.value) return

  const characterData = {
    cid: selectedSlot.value + 1,
    firstname: formData.value.firstname.trim(),
    lastname: formData.value.lastname.trim(),
    birthdate: formData.value.birthdate,
    nationality: formData.value.nationality,
    gender: formData.value.gender
  }

  await fetchNui('createCharacter', characterData)

  formData.value = {
    firstname: '',
    lastname: '',
    birthdate: '',
    nationality: 'USA',
    gender: 0
  }
  showCreation.value = false
}

const handleCloseCreation = () => {
  showCreation.value = false
  selectedSlot.value = 0
}

const handleClose = async () => {
  await fetchNui('closeUI', {})
}

const selectNationality = (nat) => {
  formData.value.nationality = nat
  showNationalityDropdown.value = false
}

const toggleNationalityDropdown = () => {
  showNationalityDropdown.value = !showNationalityDropdown.value
}

const handleKeydown = (event) => {
  if (showCreation.value) return // Karakter oluşturma formunda iken arrow key'leri devre dışı bırak

  if (event.key === 'ArrowLeft') {
    event.preventDefault()
    if (selectedSlot.value === -1) {
      selectSlot(0)
    } else {
      const newIndex = selectedSlot.value > 0 ? selectedSlot.value - 1 : slots.value.length - 1
      selectSlot(newIndex)
    }
  } else if (event.key === 'ArrowRight') {
    event.preventDefault()
    if (selectedSlot.value === -1) {
      selectSlot(0)
    } else {
      const newIndex = selectedSlot.value < slots.value.length - 1 ? selectedSlot.value + 1 : 0
      selectSlot(newIndex)
    }
  } else if (event.key === 'Enter' && !isTransitioning.value && currentCharacter.value) {
    event.preventDefault()
    handlePlay()
  }
}

onMounted(() => {
  window.addEventListener('keydown', handleKeydown)


})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)

  const currentChar = currentCharacter.value
  if (currentChar && !currentChar.isEmpty) {
    localStorage.setItem('lastSelectedCharacter', currentChar.character.citizenid)
  }
})
</script>

<template>
  <div class="multicharacter-container">
    <div class="left-panel">
      <Transition name="fade-slide" mode="out-in">
        <div v-if="!currentCharacter" class="empty-slot-info" key="no-selection">
          <h1 class="character-name">SELECT A CHARACTER</h1>
          <p class="citizen-id">Choose a slot to continue</p>
        </div>
        <div v-else-if="currentCharacter.isEmpty && showCreation" class="character-creation-form" key="creation">
          <h1 class="form-title">CREATE CHARACTER</h1>
          <p class="form-subtitle">Fill in the details below</p>

        <div class="form-inputs">
          <div class="input-group">
            <label>First Name</label>
            <input
              v-model="formData.firstname"
              type="text"
              placeholder="Enter first name"
              maxlength="50"
            />
          </div>
          <div class="input-group">
            <label>Last Name</label>
            <input
              v-model="formData.lastname"
              type="text"
              placeholder="Enter last name"
              maxlength="50"
            />
          </div>

          <div class="input-group">
            <label>Birth Date</label>
            <input
              v-model="formData.birthdate"
              type="date"
              min="1900-01-01"
              :max="new Date().toISOString().split('T')[0]"
            />
          </div>

          <div class="input-group">
            <label>Nationality</label>
            <div class="custom-select" @click="toggleNationalityDropdown">
              <div class="selected-value">{{ formData.nationality }}</div>
              <div v-if="showNationalityDropdown" class="dropdown-options">
                <div
                  v-for="nat in nationalityOptions"
                  :key="nat"
                  class="dropdown-option"
                  :class="{ active: formData.nationality === nat }"
                  @click.stop="selectNationality(nat)"
                >
                  {{ nat }}
                </div>
              </div>
            </div>
          </div>

          <div class="input-group">
            <label>Gender</label>
            <div class="gender-buttons">
              <button
                v-for="option in genderOptions"
                :key="option.value"
                :class="['gender-btn', { active: formData.gender === option.value }]"
                @click="formData.gender = option.value"
              >
                {{ option.label }}
              </button>
            </div>
          </div>
          </div>
        </div>

        <div v-else-if="!currentCharacter.isEmpty" class="character-info" key="info">
          <h1 class="character-name">{{ fullName }}</h1>
          <p class="citizen-id">CITIZEN ID</p>

        <div class="info-grid">
          <div class="info-item">
            <div class="info-icon-wrapper">
              <svg class="info-icon-svg" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M5.05 4.05a7 7 0 119.9 9.9L10 18.9l-4.95-4.95a7 7 0 010-9.9zM10 11a2 2 0 100-4 2 2 0 000 4z" clip-rule="evenodd"/>
              </svg>
            </div>
            <div class="info-content">
              <span class="info-label">Nationality</span>
              <span class="info-value">{{ charInfo?.nationality || 'USA' }}</span>
            </div>
          </div>

          <div class="info-item">
            <div class="info-icon-wrapper">
              <svg class="info-icon-svg" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clip-rule="evenodd"/>
              </svg>
            </div>
            <div class="info-content">
              <span class="info-label">Birth Date</span>
              <span class="info-value">{{ charInfo?.birthdate || '1990-01-01' }}</span>
            </div>
          </div>

          <div class="info-item">
            <div class="info-icon-wrapper">
              <svg class="info-icon-svg" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M6 6V5a3 3 0 013-3h2a3 3 0 013 3v1h2a2 2 0 012 2v3.57A22.952 22.952 0 0110 13a22.95 22.95 0 01-8-1.43V8a2 2 0 012-2h2zm2-1a1 1 0 011-1h2a1 1 0 011 1v1H8V5zm1 5a1 1 0 011-1h.01a1 1 0 110 2H10a1 1 0 01-1-1z" clip-rule="evenodd"/>
              </svg>
            </div>
            <div class="info-content">
              <span class="info-label">Job</span>
              <span class="info-value">{{ job?.label || 'POLICE' }}</span>
              <span class="info-subtext">{{ job?.grade?.name || 'Officer' }}</span>
            </div>
          </div>

          <div class="info-item">
            <div class="info-icon-wrapper">
              <svg class="info-icon-svg" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd"/>
              </svg>
            </div>
            <div class="info-content">
              <span class="info-label">Played Time</span>
              <span class="info-value">31 HOURS 31 MINUTES</span>
            </div>
          </div>

          <div class="info-item info-item-wide">
            <div class="info-icon-wrapper">
              <svg class="info-icon-svg" fill="currentColor" viewBox="0 0 20 20">
                <path d="M8.433 7.418c.155-.103.346-.196.567-.267v1.698a2.305 2.305 0 01-.567-.267C8.07 8.34 8 8.114 8 8c0-.114.07-.34.433-.582zM11 12.849v-1.698c.22.071.412.164.567.267.364.243.433.468.433.582 0 .114-.07.34-.433.582a2.305 2.305 0 01-.567.267z"/>
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-13a1 1 0 10-2 0v.092a4.535 4.535 0 00-1.676.662C6.602 6.234 6 7.009 6 8c0 .99.602 1.765 1.324 2.246.48.32 1.054.545 1.676.662v1.941c-.391-.127-.68-.317-.843-.504a1 1 0 10-1.51 1.31c.562.649 1.413 1.076 2.353 1.253V15a1 1 0 102 0v-.092a4.535 4.535 0 001.676-.662C13.398 13.766 14 12.991 14 12c0-.99-.602-1.765-1.324-2.246A4.535 4.535 0 0011 9.092V7.151c.391.127.68.317.843.504a1 1 0 101.511-1.31c-.563-.649-1.413-1.076-2.354-1.253V5z" clip-rule="evenodd"/>
              </svg>
            </div>
            <div class="info-content">
              <span class="info-label">Cash</span>
              <span class="info-value money-value">{{ formatMoney(money?.cash || 0) }}</span>
            </div>
          </div>

          <div class="info-item info-item-wide">
            <div class="info-icon-wrapper">
              <svg class="info-icon-svg" fill="currentColor" viewBox="0 0 20 20">
                <path d="M4 4a2 2 0 00-2 2v1h16V6a2 2 0 00-2-2H4z"/>
                <path fill-rule="evenodd" d="M18 9H2v5a2 2 0 002 2h12a2 2 0 002-2V9zM4 13a1 1 0 011-1h1a1 1 0 110 2H5a1 1 0 01-1-1zm5-1a1 1 0 100 2h1a1 1 0 100-2H9z" clip-rule="evenodd"/>
              </svg>
            </div>
            <div class="info-content">
              <span class="info-label">Bank</span>
              <span class="info-value money-value">{{ formatMoney(money?.bank || 0) }}</span>
            </div>
          </div>

          <div class="info-item info-item-wide">
            <div class="info-icon-wrapper">
              <svg class="info-icon-svg" fill="currentColor" viewBox="0 0 20 20">
                <path d="M2 3a1 1 0 011-1h2.153a1 1 0 01.986.836l.74 4.435a1 1 0 01-.54 1.06l-1.548.773a11.037 11.037 0 006.105 6.105l.774-1.548a1 1 0 011.059-.54l4.435.74a1 1 0 01.836.986V17a1 1 0 01-1 1h-2C7.82 18 2 12.18 2 5V3z"/>
              </svg>
            </div>
            <div class="info-content">
              <span class="info-label">Phone Number</span>
              <span class="info-value">{{ phoneNumber }}</span>
            </div>
            </div>
          </div>
        </div>

        <div v-else class="empty-slot-info" key="empty">
          <h1 class="character-name">EMPTY SLOT</h1>
          <p class="citizen-id">Create new character</p>
        </div>
      </Transition>
    </div>

    <div class="character-display">
    </div>

    <div class="bottom-bar">
      <button
        v-if="currentCharacter && currentCharacter.isEmpty && showCreation"
        class="btn-play"
        :class="{ disabled: !isFormValid }"
        :disabled="!isFormValid"
        @click="handleCreateCharacter"
      >
        <span>CREATE</span>
      </button>
      <button v-else-if="currentCharacter && !currentCharacter.isEmpty" class="btn-play" @click="handlePlay">
        <span>PLAY</span>
      </button>

      <div class="slot-buttons">
        <button
          v-for="slot in slots"
          :key="slot.index"
          :class="['slot-btn', { active: selectedSlot === slot.index, empty: slot.isEmpty }]"
          @click="selectSlot(slot.index)"
        >
          <span v-if="slot.isEmpty" class="slot-plus">+</span>
          <span v-else class="slot-initial">{{ slot.character.charinfo ? JSON.parse(slot.character.charinfo).firstname[0] : '?' }}</span>
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.multicharacter-container {
  width: 100vw;
  height: 100vh;
  position: relative;
  overflow: hidden;
  background: transparent;
  font-family: 'Inter', 'Segoe UI', sans-serif;
}

.left-panel {
  position: absolute;
  left: 80px;
  top: 50%;
  transform: translateY(-50%);
  z-index: 10;
  max-width: 420px;
  width: 420px;
}

.character-info,
.empty-slot-info,
.character-creation-form {
  animation: fadeInLeft 0.6s ease;
}

.character-creation-form {
  max-width: 400px;
}

.form-title {
  font-size: 32px;
  font-weight: 700;
  color: #ffffff;
  margin: 0 0 5px 0;
  letter-spacing: 1px;
  text-shadow: 2px 2px 8px rgba(0, 0, 0, 0.5);
}

.form-subtitle {
  font-size: 13px;
  color: rgba(255, 255, 255, 0.6);
  margin: 0 0 30px 0;
  letter-spacing: 1px;
}

.form-inputs {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.input-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.input-group label {
  font-size: 12px;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.7);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.input-group input {
  width: 100%;
  padding: 12px 16px;
  background: rgba(20, 25, 30, 0.8);
  border: 2px solid rgba(60, 65, 70, 0.6);
  border-radius: 8px;
  color: #ffffff;
  font-size: 14px;
  font-family: inherit;
  transition: all 0.2s ease;
  appearance: none;
  -webkit-appearance: none;
  -moz-appearance: none;
}

/* Custom Select/Dropdown */
.custom-select {
  position: relative;
  width: 100%;
  cursor: pointer;
}

.selected-value {
  padding: 12px 40px 12px 16px;
  background: rgba(20, 25, 30, 0.8);
  border: 2px solid rgba(60, 65, 70, 0.6);
  border-radius: 8px;
  color: #ffffff;
  font-size: 14px;
  transition: all 0.2s ease;
  background-image: url("data:image/svg+xml,%3Csvg width='12' height='8' viewBox='0 0 12 8' fill='none' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M1 1L6 6L11 1' stroke='white' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 16px center;
}

.selected-value:hover {
  border-color: rgba(255, 255, 255, 0.3);
  background-color: rgba(25, 30, 35, 0.9);
}

.dropdown-options {
  position: absolute;
  top: calc(100% + 4px);
  left: 0;
  right: 0;
  max-height: 200px;
  overflow-y: auto;
  background: rgba(20, 25, 30, 0.98);
  border: 2px solid rgba(60, 65, 70, 0.8);
  border-radius: 8px;
  z-index: 1000;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5);
}

/* Scrollbar için dark tema */
.dropdown-options::-webkit-scrollbar {
  width: 8px;
}

.dropdown-options::-webkit-scrollbar-track {
  background: rgba(15, 20, 25, 0.8);
  border-radius: 4px;
}

.dropdown-options::-webkit-scrollbar-thumb {
  background: rgba(40, 45, 50, 0.9);
  border-radius: 4px;
}

.dropdown-options::-webkit-scrollbar-thumb:hover {
  background: rgba(50, 55, 60, 1);
}

.dropdown-option {
  padding: 12px 16px;
  color: rgba(255, 255, 255, 0.8);
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.dropdown-option:hover {
  background: rgba(40, 45, 50, 0.9);
  color: #ffffff;
}

.dropdown-option.active {
  background: rgba(50, 55, 60, 1);
  color: #ffffff;
  font-weight: 600;
}

.input-group input[type="date"] {
  padding-right: 40px;
  position: relative;
}

.input-group input:focus {
  outline: none;
  border-color: rgba(255, 255, 255, 0.4);
  background: rgba(25, 30, 35, 1);
}

.input-group input::placeholder {
  color: rgba(255, 255, 255, 0.3);
}

.input-group input[type="date"]::-webkit-calendar-picker-indicator {
  filter: invert(1);
  cursor: pointer;
  position: absolute;
  right: 10px;
  width: 16px;
  height: 16px;
}

.gender-buttons {
  display: flex;
  gap: 12px;
}

.gender-btn {
  flex: 1;
  padding: 12px;
  background: rgba(20, 25, 30, 0.8);
  border: 2px solid rgba(60, 65, 70, 0.6);
  border-radius: 8px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.7);
  transition: all 0.2s ease;
}

.gender-btn:hover {
  border-color: rgba(255, 255, 255, 0.3);
  background: rgba(25, 30, 35, 0.9);
}

.gender-btn.active {
  border-color: rgba(255, 255, 255, 0.8);
  background: rgba(30, 35, 40, 1);
  color: #ffffff;
}

.character-name {
  font-size: 42px;
  font-weight: 700;
  color: #ffffff;
  margin: 0 0 5px 0;
  letter-spacing: 1px;
  text-shadow: 2px 2px 8px rgba(0, 0, 0, 0.5);
}

.citizen-id {
  font-size: 13px;
  color: rgba(255, 255, 255, 0.7);
  margin: 0 0 30px 0;
  letter-spacing: 2px;
  text-transform: uppercase;
}

.info-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  margin-top: 30px;
}

.info-item-wide {
  grid-column: span 1;
}

.info-item {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  background: rgba(20, 25, 30, 0.6);
  padding: 18px 15px;
  border-radius: 8px;
  border: 1px solid rgba(60, 65, 70, 0.4);
  transition: all 0.3s ease;
  cursor: default;
  min-height: 80px;
}

.info-item:hover {
  background: rgba(25, 30, 35, 0.8);
  border-color: rgba(80, 85, 90, 0.6);
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
}

.info-icon-wrapper {
  width: 36px;
  height: 36px;
  min-width: 36px;
  background: rgba(11, 15, 20, 0.8);
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.info-icon-svg {
  width: 20px;
  height: 20px;
  color: rgba(255, 255, 255, 0.7);
}

.info-content {
  display: flex;
  flex-direction: column;
  gap: 4px;
  flex: 1;
}

.info-label {
  font-size: 11px;
  font-weight: 500;
  color: rgba(255, 255, 255, 0.5);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.info-value {
  font-size: 13px;
  font-weight: 600;
  color: #ffffff;
  letter-spacing: 0.3px;
}

.money-value {
  color: #4ade80;
  font-weight: 700;
  text-shadow: 0 0 10px rgba(74, 222, 128, 0.3);
}

.info-subtext {
  font-size: 11px;
  color: rgba(255, 255, 255, 0.5);
  text-transform: capitalize;
}

.annotation-box {
  margin-top: 40px;
  position: relative;
}

.annotation-line {
  width: 200px;
  height: 2px;
  background: rgba(255, 255, 255, 0.3);
  margin-bottom: 15px;
  position: relative;
}

.annotation-line::before {
  content: '';
  position: absolute;
  right: -10px;
  top: -4px;
  width: 10px;
  height: 10px;
  border-right: 2px solid rgba(255, 255, 255, 0.3);
  border-top: 2px solid rgba(255, 255, 255, 0.3);
  transform: rotate(45deg);
}

.annotation-text {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.8);
  line-height: 1.6;
  max-width: 280px;
}

.character-display {
  position: absolute;
  right: 0;
  bottom: 0;
  width: 60%;
  height: 80%;
  pointer-events: none;
}

.bottom-bar {
  position: absolute;
  bottom: 40px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 20px;
  z-index: 20;
}

.slot-buttons {
  display: flex;
  gap: 12px;
  justify-content: center;
}

.slot-btn {
  width: 70px;
  height: 70px;
  background: rgba(11, 15, 20, 0.85);
  border: 2px solid rgba(60, 65, 70, 0.5);
  border-radius: 12px 0 12px 0; /* Çapraz köşeler */
  cursor: pointer;
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0.6;
}

.slot-btn.active {
  background: rgba(20, 25, 30, 0.95);
  border: 2px solid rgba(255, 255, 255, 0.9);
  box-shadow: 0 0 0 2px rgba(255, 255, 255, 0.2), 0 4px 15px rgba(0, 0, 0, 0.5);
  opacity: 1;
  transform: scale(1.05);
}


.slot-btn:not(.active):hover {
  border-color: rgba(255, 255, 255, 0.5);
  opacity: 0.8;
  transform: scale(1.1);
}

.slot-plus {
  font-size: 32px;
  color: rgba(255, 255, 255, 0.4);
  font-weight: 300;
  transition: color 0.3s ease;
}

.slot-btn.active .slot-plus {
  color: rgba(255, 255, 255, 0.8);
}

.slot-initial {
  font-size: 24px;
  color: rgba(255, 255, 255, 0.6);
  font-weight: 700;
  transition: color 0.3s ease;
}

.slot-btn.active .slot-initial {
  color: #ffffff;
}

.btn-play {
  padding: 12px 40px;
  background: rgba(30, 35, 40, 0.95);
  border: 2px solid rgba(60, 65, 70, 0.8);
  border-radius: 12px 0 12px 0; /* Çapraz köşeler: sol-üst ve sağ-alt yuvarlatılmış */
  cursor: pointer;
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;
}

.btn-play span {
  font-size: 14px;
  font-weight: 700;
  color: #ffffff;
  letter-spacing: 1.5px;
  text-transform: uppercase;
  position: relative;
  z-index: 1;
}

.btn-play:hover {
  background: rgba(40, 45, 50, 1);
  border-color: rgba(80, 85, 90, 1);
  transform: scale(1.03);
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.5);
}

.btn-play:active {
  transform: scale(0.98);
}

.btn-play.disabled {
  opacity: 0.5;
  cursor: not-allowed;
  pointer-events: none;
}

/* Animations */
@keyframes fadeInLeft {
  from {
    opacity: 0;
    transform: translateX(-30px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

/* Vue Transition Effects */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.fade-slide-enter-active,
.fade-slide-leave-active {
  transition: all 0.4s ease;
}

.fade-slide-enter-from {
  opacity: 0;
  transform: translateX(-30px);
}

.fade-slide-leave-to {
  opacity: 0;
  transform: translateX(30px);
}
</style>
