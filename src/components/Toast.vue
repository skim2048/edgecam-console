<script setup>
import { ref, onMounted } from 'vue';

let toastInstance = null;
const toast = ref(null);

const toastMsg = ref('');
const toastImgSrc = ref(null);
const toastTitle = ref('Notice');
const toastSubtitle = ref('');

defineExpose({
  show,
});

function show(msg, src=null, title='알림', subtitle='') {
  toastMsg.value = msg;
  toastImgSrc.value = src;
  toastTitle.value = title;
  toastSubtitle.value = subtitle;
  toastInstance.show();
}

onMounted(() => {
  if (toast.value) {
    toastInstance =
      bootstrap.Toast.getOrCreateInstance(toast.value);
  }
});
</script>

<template>
  <div ref="toast" class="toast position" role="alert" aria-live="assertive" aria-atomic="true">
    <div class="toast-header">
      <img v-if="toastImgSrc" :src="toastImgSrc" class="rounded me-2">
      <strong class="me-auto">{{ toastTitle }}</strong>
      <small>{{ toastSubtitle }}</small>
      <button type="button" class="btn-close" data-bs-dismiss="toast" aria-label="Close"></button>
    </div>
    <div class="toast-body">{{ toastMsg }}</div>
  </div>
</template>

<style scoped>
.position {
  margin: 10px;
  position: absolute;
  bottom: 0;
  right: 0;
}
</style>