<script setup>
import { ref, reactive, onMounted, watch } from 'vue';

import axios from 'axios';

import IconButton from '@/components/IconButton.vue';
import Toast from '@/components/Toast.vue';
import WebSock from '@/components/WebSock.vue';
import AutoFitImg from '@/components/AutoFitImg.vue';
import RoiCanvas from '@/components/RoiCanvas.vue';

const props = defineProps({
  camId: { type: String, required: true },
});

const edgecamEngine = `${import.meta.env.VITE_EDGECAM_ENGINE_IP}:12921`;

const imgNoCam = '/nocam.svg';
const imgSource = ref(imgNoCam);

const autoFitImgLocked = ref(true);

const roiCanvas = ref(null);
const roiCanvasLocked = ref(true);

const roiColors = ref(['red']);
const selectedRoi = ref(0);

// const toolbarTitle = ref('');
const rtspInput = ref('');
const LockButtonBackgrundColor = ref('transparent');

const toast = ref(null);

const webSocket = ref(null);
const webSocketURI = ref(null);
const webSocketOpened = ref(false);

const mContainer = ref(null);
const onEvent = ref(false);

const renderingSpec = reactive({
  'rois': [],
});

function updateImgSource(data) {
  URL.revokeObjectURL(imgSource.value);
  imgSource.value = URL.createObjectURL(data);
}

function openWebSocket() {
  webSocket.value.open(webSocketURI.value);
}

// function sendWebSocket(data) {
//   webSocket.value.send(data);
// }

function closeWebSocket() {
  webSocket.value.close();
}

function showToast(message) {
  if (toast.value) {
    toast.value.show(message);
  }
}

function startStreaming(locationData) {
  axios.post(`http://${edgecamEngine}/streaming/start`, { location: locationData })
    .then(response => {
      webSocketURI.value = `ws://${edgecamEngine}/stream1`;
      autoFitImgLocked.value = false;
      openWebSocket();
      axios.get(`http://${edgecamEngine}/get/roi`)
      .then(response => {
        if (response.data.status === 'success') {
          renderingSpec.rois = response.data.rois;
          console.log('Loaded ROI data:', renderingSpec.rois);
          roiCanvas.value.loadRois(response.data.rois);
        }
      })
      .catch(error => {
        console.error('Failed to load ROI data:', error.response?.data || error.message);
      });
      console.log('Successfully started streaming:', response.data);
    })
    .catch(error => {
      console.error('Failed to start streaming:', error.response?.data || error.message);
    });
}

function stopStreaming() {
  axios.post(`http://${edgecamEngine}/streaming/stop`)
    .then(response => {
      autoFitImgLocked.value = true;
      closeWebSocket();
      console.log('Successfully stopped streaming:', response.data);
    })
    .catch(error => {
      console.error('Failed to stop streaming:', error.response?.data || error.message);
    });
}

function storeConfigs() {
  axios.post(`http://${edgecamEngine}/configs/store`)
    .then(response => {
      console.log('Successfully stored configs:', response.data);
    })
    .catch(error => {
      console.error('Failed to store configs:', error.response?.data || error.message);
    });
}

function sendRoiToServer(roisData) {
  axios.post(`http://${edgecamEngine}/update/roi`, { rois: roisData })
    .then(response => {
      console.log('Successfully sent ROI data to the server:', response.data);
    })
    .catch(error => {
      console.error('Failed to send ROI data to the server:', error);
    });
}

// 추론 임계값 설정
// function sendConfThresToServer(confThres) {
//   axios.post(`http://${edgecamEngine}/update/conf-thres`, { conf_thres: confThres })
//     .then(response => {
//       console.log('Successfully updated confidence threshold:', response.data);
//     })
//     .catch(error => {
//       console.error('Failed to update confidence threshold:', error.response?.data || error.message);
//     });
// }

// 비식별 박스 크기 스케일링 계수 설정
// function sendScaleFactorToServer(scaleFactor) {
//   axios.post(`http://${edgecamEngine}/update/scale-factor`, { scale_factor: scaleFactor })
//     .then(response => {
//       console.log('Successfully updated scale factor:', response.data);
//     })
//     .catch(error => {
//       console.error('Failed to update scale factor:', error.response?.data || error.message);
//     });
// }

// 픽셀레이트 사이즈 설정
// function sendPixelSizeToServer(pixelSize) {
//   axios.post(`http://${edgecamEngine}/update/pixel-size`, { pixel_size: pixelSize })
//     .then(response => {
//       console.log('Successfully updated pixel size:', response.data);
//     })
//     .catch(error => {
//       console.error('Failed to update pixel size:', error.response?.data || error.message);
//     });
// }

watch(webSocketOpened, () => {
  if (webSocketOpened.value) {
    const roisData = renderingSpec.rois;
    sendRoiToServer(roisData);
  } else {
    imgSource.value = imgNoCam;
    onEvent.value = false;
  }
});

watch(renderingSpec, () => {
  const roisData = renderingSpec.rois;
  sendRoiToServer(roisData);
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

onMounted(() => {
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
      <!--
      <p class="col m-0 mx-1 p-0">
        {{ toolbarTitle }}
      </p>
      -->
      <div class="col m-0 mx-1 p-0 d-flex align-items-center">
        <input v-model="rtspInput" type="text" class="form-control form-control-sm me-2" placeholder="Enter RTSP URL">
      </div>

      <IconButton
        class="col-auto icon-btn"
        :icon-href="'/icons.svg#play-fill'"
        :btn-width="23"
        :btn-height="23"
        :btn-padding="0"
        @on-toggled="() => startStreaming(rtspInput)">
      </IconButton>

      <IconButton
        class="col-auto icon-btn"
        :icon-href="'/icons.svg#floppy2-fill'"
        :btn-width="23"
        :btn-height="23"
        :btn-padding="10"
        @on-toggled="() => storeConfigs()">
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
        @on-toggled="() => stopStreaming()">
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