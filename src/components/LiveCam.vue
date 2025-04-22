<script setup>
import { ref, reactive, onMounted, watch, inject } from 'vue';

import IconButton from '@/components/IconButton.vue';
import Toast from '@/components/Toast.vue';
import WebSock from '@/components/WebSock.vue';
import AutoFitImg from '@/components/AutoFitImg.vue';
import RoiCanvas from '@/components/RoiCanvas.vue';

const props = defineProps({
  camId: { type: String, required: true },
});

const imgNoCam = '/nocam.svg';
const imgSource = ref(imgNoCam);

const autoFitImgLocked = ref(true);

const roiCanvas = ref(null);
const roiCanvasLocked = ref(true);

const roiColors = ref(['red', 'blue', 'green', 'orange']);
const selectedRoi = ref(0);

const toolbarTitle = ref('');
const LockButtonBackgrundColor = ref('transparent');

const toast = ref(null);

const webSocket = ref(null);
const webSocketURI = ref(null);
const webSocketOpened = ref(false);
const webSocketReader = ref(null);

const mContainer = ref(null);
const onEvent = ref(false);

const threshold = reactive({red: 0, blue: 0, green: 0, orange: 0});
const renderingSpec = reactive({
  'rendering': false,
  'rois': [[], [], [], []],
  'threshold': [0, 0, 0, 0],
});

function updateImgSource(data) {
  if (!autoFitImgLocked.value) {
    webSocketReader.value.readAsArrayBuffer(data);
  }
}

function openWebSocket() {
  webSocket.value.open(webSocketURI.value);
}

function sendWebSocket(data) {
  webSocket.value.send(data);
}

function closeWebSocket() {
  webSocket.value.close();
}

function showToast(message) {
  if (toast.value) {
    toast.value.show(message);
  }
}

watch(threshold, () => {
  renderingSpec.threshold = [
    threshold.red,
    threshold.blue,
    threshold.green,
    threshold.orange
  ];
});

watch(webSocketOpened, () => {
  if (webSocketOpened.value) {
    sendWebSocket(JSON.stringify(renderingSpec));
  }
  else {
    imgSource.value = imgNoCam;
    toolbarTitle.value = '';
    onEvent.value = false;
  }
});

watch(roiCanvasLocked, () => {
  if (roiCanvasLocked.value) {
    LockButtonBackgrundColor.value = 'transparent';
  }
  else {
    LockButtonBackgrundColor.value =
      roiColors.value[selectedRoi.value];
  }
});

watch(renderingSpec, () => {
  if (webSocketOpened.value) {
    sendWebSocket(JSON.stringify(renderingSpec));
  }
});

onMounted(() => {
  webSocketURI.value = 'ws://172.27.1.125:8080/inference/det/0';
  autoFitImgLocked.value = false;
  openWebSocket();

  webSocketReader.value = new FileReader();
  webSocketReader.value.onload = function() {
    const arrayBuffer = webSocketReader.value.result;
    const dataView = new DataView(arrayBuffer);

    const length = dataView.getUint32(0, false);
    const eventsJson = new TextDecoder().decode(new Uint8Array(arrayBuffer, 4, length));
    const events = JSON.parse(eventsJson);

    const frameStart = 4 + length;
    const frame = arrayBuffer.slice(frameStart);

    URL.revokeObjectURL(imgSource.value);
    imgSource.value = URL.createObjectURL(new Blob([frame]));
  }
});
</script>

<template>
  <div ref="mContainer" :class="`m-container border border-3 ${onEvent ? 'border-danger' : 'border-light-subtle'}`">

    <WebSock
      ref="webSocket"
      @on-notification="showToast"
      @on-data-received="updateImgSource"
      @on-open-state-changed="state => webSocketOpened = state">
    </WebSock>

    <div class="row align-items-center m-0 ps-1 border-bottom">
      <span
        :class="`col-auto badge position-relative m-0 p-1
        ${webSocketOpened ? 'text-bg-success' : 'text-bg-danger'}`">
        {{ camId }}
      </span>
      <p class="col m-0 mx-1 p-0">
        {{ toolbarTitle }}
      </p>

      <IconButton
        class="col-auto icon-btn"
        :icon-href="'/icons.svg#eye-slash-fill'"
        :icon-pressed-href="'/icons.svg#eye-fill'"
        :btn-width="23"
        :btn-height="23"
        :btn-padding="10"
        @on-toggled="state => renderingSpec.rendering = state">
      </IconButton>

      <IconButton
        class="col-auto icon-btn"
        :icon-href="'/icons.svg#lock-fill'"
        :icon-pressed-href="'/icons.svg#unlock-fill'"
        :btn-width="23"
        :btn-height="23"
        :btn-padding="10"
        :btn-background-color="LockButtonBackgrundColor"
        @on-toggled="state => roiCanvasLocked = !state">
      </IconButton>

      <IconButton
        class="col-auto icon-btn"
        :icon-href="'/icons.svg#trash-fill'"
        :btn-width="23"
        :btn-height="23"
        :btn-padding="10"
        @on-toggled="roiCanvas.deleteRoi()">
      </IconButton>

      <IconButton
        class="col-auto icon-btn"
        :icon-href="'/icons.svg#x-lg'"
        :btn-width="23"
        :btn-height="23"
        :btn-padding="10"
        @on-toggled="closeWebSocket">
      </IconButton>
    </div>

    <div class="livecam-screen">
      <AutoFitImg
        :src="imgSource"
        @size-updated="(width, height) => roiCanvas.resizeCanvas(width, height)">
      </AutoFitImg>

      <RoiCanvas
        ref="roiCanvas"
        class="position-absolute"
        :locked="roiCanvasLocked"
        :roiColors="roiColors"
        :selectedRoi="selectedRoi"
        @onRoisModified="roisPoints => renderingSpec.rois = roisPoints">
      </RoiCanvas>

      <Toast ref="toast"/>
    </div>
  </div>
</template>

<style scoped>
.m-container {
  margin: 0px;
  display: flex;
  flex-direction: column;
}

.livecam-screen {
  position: relative;
  display: flex;
  flex-grow: 1;
  align-items: center;
  justify-content: center;
  background-color: black;
  overflow: hidden;
}
.icon-btn {
  margin-block: 2px;
  margin-right: 3px;
  border-style: solid;
  border-width: 1px;
  border-radius: 20%;
}
</style>