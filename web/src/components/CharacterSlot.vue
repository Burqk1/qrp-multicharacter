<script setup>
import { computed } from 'vue'

const props = defineProps({
  slot: {
    type: Object,
    required: true
  },
  isSelected: {
    type: Boolean,
    default: false
  },
  isHovered: {
    type: Boolean,
    default: false
  }
})

const charInfo = computed(() => {
  if (!props.slot.character?.charinfo) return null
  try {
    return JSON.parse(props.slot.character.charinfo)
  } catch {
    return null
  }
})

const job = computed(() => {
  if (!props.slot.character?.job) return null
  try {
    return JSON.parse(props.slot.character.job)
  } catch {
    return null
  }
})

const fullName = computed(() => {
  if (!charInfo.value) return null
  return `${charInfo.value.firstname} ${charInfo.value.lastname}`
})
</script>

<template>
  <div
    :class="[
      'relative group cursor-pointer rounded-xl overflow-hidden transition-all duration-300 transform',
      'bg-gradient-to-br from-slate-800/50 to-slate-900/50 backdrop-blur-sm',
      'border-2',
      isSelected
        ? 'border-blue-500 scale-105 shadow-2xl shadow-blue-500/50'
        : isHovered
          ? 'border-blue-400/50 scale-102 shadow-xl shadow-blue-400/30'
          : 'border-gray-700/50 hover:border-gray-600',
      'min-h-[280px]'
    ]"
  >
    <div class="absolute top-3 left-3 z-10">
      <div class="flex items-center justify-center w-8 h-8 rounded-full bg-slate-900/80 border border-gray-600">
        <span class="text-sm font-bold text-gray-300">{{ slot.index + 1 }}</span>
      </div>
    </div>

    <div v-if="slot.isEmpty" class="flex flex-col items-center justify-center h-full p-8 min-h-[280px]">
      <div class="mb-4 transform transition-transform duration-300 group-hover:scale-110">
        <svg class="w-16 h-16 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
        </svg>
      </div>
      <p class="text-gray-400 font-semibold text-lg">Boş Slot</p>
      <p class="text-gray-500 text-sm mt-2">Yeni karakter oluştur</p>
    </div>

    <div v-else class="flex flex-col h-full p-6 min-h-[280px]">
      <div class="flex items-center justify-center mb-4">
        <div class="w-20 h-20 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center shadow-lg">
          <svg class="w-12 h-12 text-white" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd"/>
          </svg>
        </div>
      </div>

      <div class="text-center mb-4">
        <h3 class="text-xl font-bold text-white mb-1">{{ fullName }}</h3>
        <p class="text-sm text-gray-400">{{ charInfo?.nationality || 'Unknown' }}</p>
      </div>

      <div class="space-y-2 mt-auto">
        <div v-if="job" class="flex items-center justify-between bg-slate-900/50 rounded-lg px-3 py-2">
          <span class="text-xs text-gray-400">Meslek</span>
          <span class="text-sm font-semibold text-blue-400">{{ job.label }}</span>
        </div>

        <div v-if="charInfo?.birthdate" class="flex items-center justify-between bg-slate-900/50 rounded-lg px-3 py-2">
          <span class="text-xs text-gray-400">Doğum Tarihi</span>
          <span class="text-sm font-semibold text-gray-300">{{ charInfo.birthdate }}</span>
        </div>
      </div>
    </div>

    <div
      v-if="isSelected"
      class="absolute inset-0 border-2 border-blue-500 rounded-xl pointer-events-none"
    >
      <div class="absolute top-0 right-0 m-3">
        <div class="flex items-center justify-center w-8 h-8 rounded-full bg-blue-500 shadow-lg shadow-blue-500/50">
          <svg class="w-5 h-5 text-white" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
          </svg>
        </div>
      </div>
    </div>

    <div
      :class="[
        'absolute inset-0 opacity-0 transition-opacity duration-300 pointer-events-none rounded-xl',
        isHovered && 'opacity-100'
      ]"
      style="background: radial-gradient(circle at center, rgba(59, 130, 246, 0.1), transparent 70%)"
    ></div>
  </div>
</template>
