<script setup>
import { onMounted, onUnmounted, ref } from 'vue';

const emits = defineEmits([
  'sizeUpdated'
])

const img = ref(null);

let parentResizeObserver = null;

function resizeTo(parent) {
  const parentWidth = parent.contentRect.width;
  const parentHeight = parent.contentRect.height;
  const imgWidth = img.value.naturalWidth;
  const imgHeight = img.value.naturalHeight;

  const widthRatio = parentWidth / imgWidth;
  const heightRatio = parentHeight / imgHeight;
  const resizeFactor =
    widthRatio < heightRatio ? widthRatio : heightRatio;

  const resizedWidth = Math.floor(imgWidth * resizeFactor);
  const resizedHeight = Math.floor(imgHeight * resizeFactor);
  img.value.width = resizedWidth;
  img.value.height = resizedHeight;
  emits('sizeUpdated', resizedWidth, resizedHeight);
}

async function waitFirstImgToLoad() {
  while (img.value.naturalWidth === 0 && img.value.naturalHeight === 0) {
    await new Promise(resolve => setTimeout(resolve, 100));
  }
}

function setupParentResizeObserver() {
  parentResizeObserver = new ResizeObserver(entries => {
    for (let entry of entries) {
      resizeTo(entry);
    }
  });
  parentResizeObserver.observe(img.value.parentElement);
}

onMounted(() => {
  if (img.value && img.value.parentElement) {
    waitFirstImgToLoad().then(setupParentResizeObserver);
  }
});

onUnmounted(() => {
  if (parentResizeObserver) {
    parentResizeObserver.disconnect();
  }
});
</script>

<template>
  <img ref="img" draggable="false"/>
</template>

<style scoped>
img {
  margin: 0px;
  padding: 0px;
}
</style>