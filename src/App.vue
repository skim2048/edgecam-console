<script setup>
import LiveCam from '@/components/LiveCam.vue'
</script>

<template>
  <div class="app-container">
    <LiveCam :cam-id="`CAM 0`" class="w-100 h-100 m-0 p-0" />
  </div>
</template>

<style scoped>
.app-container {
  margin: 0px;
  padding: 0px;
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
}
</style>