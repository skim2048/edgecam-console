<script setup>
import { onBeforeUnmount } from 'vue';

const emits = defineEmits([
  'onNotification',
  'onDataReceived',
  'onOpenStateChanged',
]);

defineExpose({
  open, close, send
});

let webSocket = null;
let prevOpenState = false;

const connectionAlreadyEstablished = 
'현재 연결이 이미 설정되어 있습니다. 새로운 연결을 생성하려면 기존 연결을 종료해 주세요.';

const connectionNotEstablished = 
'현재 설정된 연결이 없습니다. 먼저 새 연결을 생성해 주세요.';

const connectionEstablished = 
'새 연결이 성공적으로 설정되었습니다. 스트리밍을 시작합니다.';

const connectionClosed = 
'연결이 성공적으로 종료되었습니다. 스트리밍을 종료합니다.';

const errorOccurred = 
'예기치 않은 오류가 발생했습니다. 자세한 내용은 콘솔을 확인해 주세요.';

function isOpened() {
  return webSocket && 
         webSocket.readyState === WebSocket.OPEN;
}

function open(uri) {
  if (isOpened()) {
    notify(connectionAlreadyEstablished);
    return;
  }

  webSocket = new WebSocket(uri);
  webSocket.binaryType = 'blob';

  webSocket.onopen = () => {
    notify(connectionEstablished);
    changeOpenState();
  };
  webSocket.onclose = (event) => {
    if (event.wasClean) {
      notify(connectionClosed);
    }
    else {
      notify(`${connectionClosed} However, ${errorOccurred}`);
      console.error(event);
    }
    changeOpenState();
  };
  webSocket.onerror = (event) => {
    notify(errorOccurred);
    console.error(event);
    changeOpenState();
  };
  webSocket.onmessage = (event) => {
    emits('onDataReceived', event.data);
  };
}

function close() {
  if (isOpened()) {
    webSocket.close(1000);
    webSocket = null;
    changeOpenState();
  }
  else {
    notify(connectionNotEstablished);
  }
}

function send(data) {
  if (!isOpened()) {
    notify(connectionNotEstablished);
    return;
  }
  webSocket.send(data);
}

function notify(msg) {
  emits('onNotification', msg);
}

function changeOpenState() {
  const currOpenState = isOpened();
  if (prevOpenState !== currOpenState) {
    prevOpenState = currOpenState;
    emits('onOpenStateChanged', currOpenState);
  }
}

onBeforeUnmount(() => {
  close();
});
</script>

<template>
</template>

<style scoped>
</style>