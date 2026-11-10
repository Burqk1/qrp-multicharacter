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
  },
  deleteEnabled: {
    type: Boolean,
    default: false
  },
  requireConfirmation: {
    type: Boolean,
    default: true
  },
  defaultLanguage: {
    type: String,
    default: 'en'
  }
})

const selectedSlot = ref(-1)
const showCreation = ref(false)
const showNationalityDropdown = ref(false)
const isTransitioning = ref(false)
const currentLanguage = ref(props.defaultLanguage === 'tr' ? 'tr' : 'en')
const confirmingDelete = ref(false)

const translations = {
  en: {
    selectCharacter: 'SELECT A CHARACTER',
    chooseSlot: 'Choose a slot to continue',
    createCharacter: 'CREATE CHARACTER',
    fillDetails: 'Fill in the details below',
    firstName: 'First Name',
    lastName: 'Last Name',
    birthDate: 'Birth Date',
    nationality: 'Nationality',
    gender: 'Gender',
    male: 'Male',
    female: 'Female',
    create: 'CREATE',
    play: 'PLAY',
    delete: 'DELETE',
    confirmDelete: 'CONFIRM DELETE',
    emptySlot: 'EMPTY SLOT',
    createNew: 'Create new character',
    personalInfo: 'Personal Information',
    careerStats: 'Career & Statistics',
    currentJob: 'Current Job',
    playTime: 'Play Time',
    bankBalance: 'Bank Balance',
    phoneNumber: 'Phone Number',
    unemployed: 'Unemployed',
    noPosition: 'No Position',
    enterFirstName: 'Enter first name',
    enterLastName: 'Enter last name'
  },
  tr: {
    selectCharacter: 'BİR KARAKTER SEÇİN',
    chooseSlot: 'Devam etmek için bir slot seçin',
    createCharacter: 'KARAKTER OLUŞTUR',
    fillDetails: 'Aşağıdaki bilgileri doldurun',
    firstName: 'Ad',
    lastName: 'Soyad',
    birthDate: 'Doğum Tarihi',
    nationality: 'Uyruk',
    gender: 'Cinsiyet',
    male: 'Erkek',
    female: 'Kadın',
    create: 'OLUŞTUR',
    play: 'OYNA',
    delete: 'SİL',
    confirmDelete: 'SİLMEYİ ONAYLA',
    emptySlot: 'BOŞ SLOT',
    createNew: 'Yeni karakter oluştur',
    personalInfo: 'Kişisel Bilgiler',
    careerStats: 'Kariyer & İstatistikler',
    currentJob: 'Mevcut İş',
    playTime: 'Oyun Süresi',
    bankBalance: 'Banka Bakiyesi',
    phoneNumber: 'Telefon Numarası',
    unemployed: 'İşsiz',
    noPosition: 'Pozisyon Yok',
    enterFirstName: 'Adınızı girin',
    enterLastName: 'Soyadınızı girin'
  }
}

const t = computed(() => (key) => {
  return translations[currentLanguage.value][key] || key
})

const formData = ref({
  firstname: '',
  lastname: '',
  birthdate: '',
  nationality: 'USA',
  gender: 0
})

const genderOptions = computed(() => [
  { label: t.value('male'), value: 0 },
  { label: t.value('female'), value: 1 }
])

const toggleLanguage = () => {
  currentLanguage.value = currentLanguage.value === 'en' ? 'tr' : 'en'
}

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

const playTime = computed(() => {
  const metadata = currentCharacter.value?.character?.metadata
  if (!metadata) return '0 Hours 0 Min'

  try {
    const meta = typeof metadata === 'string' ? JSON.parse(metadata) : metadata
    const totalMinutes = meta?.playtime || 0
    const hours = Math.floor(totalMinutes / 60)
    const minutes = totalMinutes % 60

    if (currentLanguage.value === 'tr') {
      return `${hours} Saat ${minutes} Dakika`
    }
    return `${hours} Hours ${minutes} Min`
  } catch {
    return currentLanguage.value === 'tr' ? '0 Saat 0 Dakika' : '0 Hours 0 Min'
  }
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

  confirmingDelete.value = false
  selectedSlot.value = index
  const slot = slots.value[index]

  if (slot.isEmpty) {
    showCreation.value = true
    await fetchNui('changeSlot', { citizenid: null })
    isTransitioning.value = false
  } else {
    showCreation.value = false
    await fetchNui('changeSlot', { citizenid: slot.character.citizenid })

    setTimeout(() => {
      isTransitioning.value = false
    }, 400)
  }
}

const handlePlay = async () => {
  const slot = currentCharacter.value
  if (slot.isEmpty) {
  
    return
  } else {
    await fetchNui('selectCharacter', { citizenid: slot.character.citizenid })
  }
}

const handleDelete = async () => {
  const slot = currentCharacter.value
  if (!props.deleteEnabled || !slot || slot.isEmpty) return

  if (props.requireConfirmation && !confirmingDelete.value) {
    confirmingDelete.value = true
    return
  }

  confirmingDelete.value = false
  await fetchNui('deleteCharacter', { citizenid: slot.character.citizenid })
  await fetchNui('changeSlot', { citizenid: null })
  selectedSlot.value = -1
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
  if (showCreation.value) return 

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
          <h1 class="character-name">{{ t('selectCharacter') }}</h1>
          <p class="citizen-id">{{ t('chooseSlot') }}</p>
        </div>
        <div v-else-if="currentCharacter.isEmpty && showCreation" class="character-creation-form" key="creation">
          <h1 class="form-title">{{ t('createCharacter') }}</h1>
          <p class="form-subtitle">{{ t('fillDetails') }}</p>

        <div class="form-inputs">
          <div class="input-group">
            <label>{{ t('firstName') }}</label>
            <input
              v-model="formData.firstname"
              type="text"
              :placeholder="t('enterFirstName')"
              maxlength="50"
            />
          </div>
          <div class="input-group">
            <label>{{ t('lastName') }}</label>
            <input
              v-model="formData.lastname"
              type="text"
              :placeholder="t('enterLastName')"
              maxlength="50"
            />
          </div>

          <div class="input-group">
            <label>{{ t('birthDate') }}</label>
            <input
              v-model="formData.birthdate"
              type="date"
              min="1900-01-01"
              :max="new Date().toISOString().split('T')[0]"
            />
          </div>

          <div class="input-group">
            <label>{{ t('nationality') }}</label>
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
            <label>{{ t('gender') }}</label>
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
          <!-- Header Section -->
          <div class="info-header">
            <div class="header-content">
              <h1 class="character-name">{{ fullName }}</h1>
              <div class="citizen-badge">
                <svg class="badge-icon" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z" clip-rule="evenodd"/>
                </svg>
                <span class="citizen-id">{{ currentCharacter.character.citizenid || 'CID12345' }}</span>
              </div>
            </div>
          </div>

          <!-- Info Cards Grid -->
          <div class="info-cards">
            <!-- Personal Info Section -->
            <div class="info-section">
              <div class="section-title">
                <div class="title-line"></div>
                <span>{{ t('personalInfo') }}</span>
              </div>

              <div class="info-card">
                <div class="card-icon nationality">
                  <svg fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M5.05 4.05a7 7 0 119.9 9.9L10 18.9l-4.95-4.95a7 7 0 010-9.9zM10 11a2 2 0 100-4 2 2 0 000 4z" clip-rule="evenodd"/>
                  </svg>
                </div>
                <div class="card-content">
                  <span class="card-label">{{ t('nationality') }}</span>
                  <span class="card-value">{{ charInfo?.nationality || 'USA' }}</span>
                </div>
              </div>

              <div class="info-card">
                <div class="card-icon birthdate">
                  <svg fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clip-rule="evenodd"/>
                  </svg>
                </div>
                <div class="card-content">
                  <span class="card-label">{{ t('birthDate') }}</span>
                  <span class="card-value">{{ charInfo?.birthdate || '1990-01-01' }}</span>
                </div>
              </div>

              <div class="info-card">
                <div class="card-icon phone">
                  <svg fill="currentColor" viewBox="0 0 20 20">
                    <path d="M2 3a1 1 0 011-1h2.153a1 1 0 01.986.836l.74 4.435a1 1 0 01-.54 1.06l-1.548.773a11.037 11.037 0 006.105 6.105l.774-1.548a1 1 0 011.059-.54l4.435.74a1 1 0 01.836.986V17a1 1 0 01-1 1h-2C7.82 18 2 12.18 2 5V3z"/>
                  </svg>
                </div>
                <div class="card-content">
                  <span class="card-label">{{ t('phoneNumber') }}</span>
                  <span class="card-value">{{ phoneNumber }}</span>
                </div>
              </div>
            </div>

            <!-- Job & Stats Section -->
            <div class="info-section">
              <div class="section-title">
                <div class="title-line"></div>
                <span>{{ t('careerStats') }}</span>
              </div>

              <div class="info-card featured">
                <div class="card-icon job">
                  <svg fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M6 6V5a3 3 0 013-3h2a3 3 0 013 3v1h2a2 2 0 012 2v3.57A22.952 22.952 0 0110 13a22.95 22.95 0 01-8-1.43V8a2 2 0 012-2h2zm2-1a1 1 0 011-1h2a1 1 0 011 1v1H8V5zm1 5a1 1 0 011-1h.01a1 1 0 110 2H10a1 1 0 01-1-1z" clip-rule="evenodd"/>
                  </svg>
                </div>
                <div class="card-content">
                  <span class="card-label">{{ t('currentJob') }}</span>
                  <span class="card-value">{{ job?.label || t('unemployed') }}</span>
                  <span class="card-subtext">{{ job?.grade?.name || t('noPosition') }}</span>
                </div>
              </div>

              <div class="info-card">
                <div class="card-icon time">
                  <svg fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd"/>
                  </svg>
                </div>
                <div class="card-content">
                  <span class="card-label">{{ t('playTime') }}</span>
                  <span class="card-value">{{ playTime }}</span>
                </div>
              </div>

              <div class="info-card money-card">
                <div class="card-icon bank">
                  <svg fill="currentColor" viewBox="0 0 20 20">
                    <path d="M4 4a2 2 0 00-2 2v1h16V6a2 2 0 00-2-2H4z"/>
                    <path fill-rule="evenodd" d="M18 9H2v5a2 2 0 002 2h12a2 2 0 002-2V9zM4 13a1 1 0 011-1h1a1 1 0 110 2H5a1 1 0 01-1-1zm5-1a1 1 0 100 2h1a1 1 0 100-2H9z" clip-rule="evenodd"/>
                  </svg>
                </div>
                <div class="card-content">
                  <span class="card-label">{{ t('bankBalance') }}</span>
                  <span class="card-value money-value">{{ formatMoney(money?.bank || 0) }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div v-else class="empty-slot-info" key="empty">
          <h1 class="character-name">{{ t('emptySlot') }}</h1>
          <p class="citizen-id">{{ t('createNew') }}</p>
        </div>
      </Transition>
    </div>

    <!-- Language Toggle Button -->
    <button class="language-toggle" @click="toggleLanguage">
      <svg fill="currentColor" viewBox="0 0 20 20">
        <path fill-rule="evenodd" d="M7 2a1 1 0 011 1v1h3a1 1 0 110 2H9.578a18.87 18.87 0 01-1.724 4.78c.29.354.596.696.914 1.026a1 1 0 11-1.44 1.389c-.188-.196-.373-.396-.554-.6a19.098 19.098 0 01-3.107 3.567 1 1 0 01-1.334-1.49 17.087 17.087 0 003.13-3.733 18.992 18.992 0 01-1.487-2.494 1 1 0 111.79-.89c.234.47.489.928.764 1.372.417-.934.752-1.913.997-2.927H3a1 1 0 110-2h3V3a1 1 0 011-1zm6 6a1 1 0 01.894.553l2.991 5.982a.869.869 0 01.02.037l.99 1.98a1 1 0 11-1.79.895L15.383 16h-4.764l-.723 1.447a1 1 0 11-1.788-.894l.99-1.98.019-.038 2.99-5.982A1 1 0 0113 8zm-1.382 6h2.764L13 11.236 11.618 14z" clip-rule="evenodd"/>
      </svg>
      <span>{{ currentLanguage.toUpperCase() }}</span>
    </button>

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
        <span>{{ t('create') }}</span>
      </button>
      <button v-else-if="currentCharacter && !currentCharacter.isEmpty" class="btn-play" @click="handlePlay">
        <span>{{ t('play') }}</span>
      </button>
      <button
        v-if="deleteEnabled && currentCharacter && !currentCharacter.isEmpty"
        class="btn-play btn-delete"
        @click="handleDelete"
      >
        <span>{{ confirmingDelete ? t('confirmDelete') : t('delete') }}</span>
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

/* Info Header Styles */
.info-header {
  margin-bottom: 30px;
}

.header-content {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.citizen-badge {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background: transparent;
  padding: 0;
  border: none;
  width: fit-content;
}

.badge-icon {
  width: 14px;
  height: 14px;
  color: rgba(255, 255, 255, 0.5);
  display: none;
}

.citizen-id {
  font-size: 13px;
  color: rgba(255, 255, 255, 0.7);
  letter-spacing: 2px;
  font-weight: 500;
  text-transform: uppercase;
}

/* Info Cards Container */
.info-cards {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* Section Styles */
.info-section {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.section-title {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
  padding-left: 4px;
}

.title-line {
  width: 2px;
  height: 12px;
  background: rgba(255, 255, 255, 0.4);
  border-radius: 1px;
}

.section-title span {
  font-size: 10px;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.5);
  text-transform: uppercase;
  letter-spacing: 1.5px;
}

/* Info Card Styles */
.info-card {
  display: flex;
  align-items: center;
  gap: 12px;
  background: rgba(11, 15, 20, 0.85);
  padding: 16px 14px;
  border-radius: 12px 0 12px 0;
  border: 2px solid rgba(60, 65, 70, 0.5);
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;
}

.info-card:hover {
  background: rgba(20, 25, 30, 0.95);
  border-color: rgba(80, 85, 90, 0.7);
  transform: translateX(2px);
}

/* Featured Card (Job Card) */
.info-card.featured {
  background: rgba(11, 15, 20, 0.9);
  border: 2px solid rgba(60, 65, 70, 0.6);
  padding: 18px 14px;
}

.info-card.featured:hover {
  background: rgba(20, 25, 30, 1);
  border-color: rgba(80, 85, 90, 0.8);
}

/* Money Card */
.info-card.money-card {
  background: rgba(11, 15, 20, 0.85);
  border: 2px solid rgba(60, 65, 70, 0.5);
}

.info-card.money-card:hover {
  background: rgba(20, 25, 30, 0.95);
  border-color: rgba(80, 85, 90, 0.7);
}

/* Card Icon Styles */
.card-icon {
  width: 36px;
  height: 36px;
  min-width: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(11, 15, 20, 0.8);
  border-radius: 6px;
  position: relative;
  transition: all 0.3s ease;
  color: rgba(255, 255, 255, 0.7);
}

.card-icon svg {
  width: 20px;
  height: 20px;
  position: relative;
  z-index: 1;
}

/* Card Content */
.card-content {
  display: flex;
  flex-direction: column;
  gap: 4px;
  flex: 1;
  min-width: 0;
}

.card-label {
  font-size: 11px;
  font-weight: 500;
  color: rgba(255, 255, 255, 0.5);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.card-value {
  font-size: 13px;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.9);
  letter-spacing: 0.3px;
}

.money-value {
  color: rgba(255, 255, 255, 0.9);
  font-size: 14px;
  font-weight: 700;
  letter-spacing: 0.3px;
}

.card-subtext {
  font-size: 11px;
  color: rgba(255, 255, 255, 0.5);
  font-weight: 500;
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

/* Language Toggle Button */
.language-toggle {
  position: absolute;
  top: 40px;
  right: 40px;
  display: flex;
  align-items: center;
  gap: 8px;
  background: rgba(11, 15, 20, 0.85);
  padding: 12px 18px;
  border-radius: 12px 0 12px 0;
  border: 2px solid rgba(60, 65, 70, 0.5);
  cursor: pointer;
  transition: all 0.3s ease;
  z-index: 100;
}

.language-toggle svg {
  width: 18px;
  height: 18px;
  color: rgba(255, 255, 255, 0.7);
}

.language-toggle span {
  font-size: 12px;
  font-weight: 700;
  color: rgba(255, 255, 255, 0.8);
  letter-spacing: 1px;
}

.language-toggle:hover {
  background: rgba(20, 25, 30, 0.95);
  border-color: rgba(80, 85, 90, 0.7);
  transform: translateY(-2px);
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

.btn-delete {
  border-color: rgba(150, 40, 40, 0.8);
}

.btn-delete:hover {
  border-color: rgba(200, 50, 50, 1);
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
