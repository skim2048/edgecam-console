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
'The current connection is already established. Please terminate \
the existing connection should you wish to create a new one.';

const connectionNotEstablished =
'No current connection is established. Please create a new \
connection first.';

const connectionEstablished =
'The new connection has been successfully established.';

const connectionClosed = 
'The connection has been successfully closed.';

const errorOccurred =
'An unexpected error has occurred, so please check the console \
for details.';

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