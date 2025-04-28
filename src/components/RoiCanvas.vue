<script setup>
import { ref, onMounted, watch } from 'vue';

class Point {
  static validate(min, max) {
    if (min === max) throw new Error(
      'min and max cannot be same.'
    );
  }
  static normalize(value, min, max) {
    Point.validate(min, max);
    return (value - min) / (max - min);
  }
  static denormalize(value, min, max) {
    Point.validate(min, max);
    return value * (max - min) + min;
  }
  constructor() {
    this.normX = 0.0;
    this.normY = 0.0;
  }
  moveTo(x, y, maxX, maxY) {
    this.normX = Point.normalize(x, 0, maxX);
    this.normY = Point.normalize(y, 0, maxY);
  }
  scaleTo(maxX, maxY) {
    const x = Point.denormalize(this.normX, 0, maxX);
    const y = Point.denormalize(this.normY, 0, maxY);
    return [x, y];
  }
}

class ROI {
  constructor(color='red') {
    this.color = color;
    this.points = [];
  }
  appendPoint(x, y, maxX, maxY) {
    const point = new Point();
    point.moveTo(x, y, maxX, maxY);
    this.points.push(point);
  }
  deletePoint(index) {
    if (index !== -1) this.points.splice(index, 1);
  }
  deletePoints() {
    this.points.splice(0, this.points.length);
  }
  _contains(point, x, y, maxX, maxY) {
    const [x_, y_] = point.scaleTo(maxX, maxY);
    const distance = Math.sqrt(((x - x_) ** 2) + ((y - y_) ** 2));
    return distance <= pointRadius.value;
  }
  findPointIndex(x, y, maxX, maxY) {
    return this.points.findIndex(point => 
      this._contains(point, x, y, maxX, maxY));
  }
  somePoint(x, y, maxX, maxY) {
    return this.points.some(point => 
      this._contains(point, x, y, maxX, maxY));
  }
  getPoints() {
    const points = this.points.map(point =>
      [point.normX, point.normY]
    );
    return points;
  }
}

const props = defineProps({
  locked: { type: Boolean, default: false },
  roiColors: { type: Object, default: ['red'] },
  selectedRoi: { type: Number, default: 0 },
});

const pointRadius = ref(3.5);
let selectedPoint = -1;

const roiCanvas = ref(null);
let canvasContext = null;

const rois = props.roiColors.map(color => new ROI(color));
const isRoisModified = ref(false);

const mouseStyle = ref('default');
let isMouseDragging = false;

const emits = defineEmits([
  'onRoisModified',
]);

defineExpose({
  getCanvas, resizeCanvas, deleteRoi, deleteRois, loadRois
});

function getCanvas() {
  return roiCanvas.value;
}

function resizeCanvas(width, height) {
  setCanvasSize(width, height);
  refreshCanvas();
}

function setCanvasSize(width, height) {
  roiCanvas.value.width = width;
  roiCanvas.value.height = height;
}

function getCanvasSize() {
  const width = roiCanvas.value.width;
  const height = roiCanvas.value.height;
  return [width, height];
}

function refreshCanvas() {
  const [width, height] = getCanvasSize();
  rois.forEach(roi => {
    roi.points.forEach((point, index) => {
      const [x, y] = point.scaleTo(width, height);
      if (index > 0) {
        const [x_, y_] =
          roi.points[index - 1].scaleTo(width, height);
        drawLineSegment(x_, y_, x, y, roi.color);
      }
      drawVertex(x, y, roi.color);
    });
    const numPoints = roi.points.length;
    if (numPoints > 2) {
      const head = roi.points[0];
      const tail = roi.points[numPoints - 1];
      const [x, y] = head.scaleTo(width, height);
      const [x_, y_] = tail.scaleTo(width, height);
      drawLineSegment(x_, y_, x, y);
    }
  });
}

function drawLineSegment(x_, y_, x, y, color) {
  canvasContext.beginPath();
  canvasContext.moveTo(x_, y_);
  canvasContext.lineTo(x, y);
  canvasContext.strokeStyle = color;
  canvasContext.stroke();
}

function drawVertex(x, y, color) {
  canvasContext.beginPath();
  canvasContext.arc(x, y, pointRadius.value, 0, Math.PI * 2, false);
  canvasContext.fillStyle = color;
  canvasContext.fill();
  canvasContext.strokeStyle = color;
  canvasContext.stroke();
}

function getMouseCoordinates(event) {
  const x = event.offsetX;
  const y = event.offsetY;
  const [width, height] = getCanvasSize();
  return [x, y, width, height];
}

function onMouseDown(event) {
  if (props.locked)
    return;
  const [x, y, width, height] = getMouseCoordinates(event);
  selectedPoint =
    rois[props.selectedRoi]
      .findPointIndex(x, y, width, height);
  if (selectedPoint !== -1) {
    isMouseDragging = true;
  } else {
    rois[props.selectedRoi]
      .appendPoint(x, y, width, height);
    isRoisModified.value = true;
  }
}

function onMouseMove(event) {
  if (props.locked)
    return;
  const [x, y, width, height] = getMouseCoordinates(event);
  const onPoint =
    rois[props.selectedRoi].somePoint(x, y, width, height);
  mouseStyle.value = onPoint ? 'grab' : 'default';
  if (selectedPoint !== -1 && isMouseDragging) {
    mouseStyle.value = 'grabbing';
    rois[props.selectedRoi]
      .points[selectedPoint]
      .moveTo(x, y, width, height);
    isRoisModified.value = true;
  }
}

function onMouseUp() {
  if (props.locked)
    return;
  mouseStyle.value = 'grab';
  isMouseDragging = false;
}

function onKeyDown(event) {
  if (props.locked)
    return;
  if (event.key === 'Delete' && selectedPoint !== -1) {
    rois[props.selectedRoi].deletePoint(selectedPoint);
    selectedPoint = -1;
    isRoisModified.value = true;
  }
}

function deleteRoi() {
  if (props.locked)
    return;
  rois[props.selectedRoi].deletePoints();
  isRoisModified.value = true;
}

function deleteRois() {
  if (props.locked)
    return;
  rois.forEach(roi => roi.deletePoints());
  isRoisModified.value = true;
}

function loadRois(newRoisData) {
  rois[0].points = newRoisData.map(([normX, normY]) => {
    const point = new Point();
    point.normX = normX;
    point.normY = normY;
    return point;
  });
  isRoisModified.value = true;
}

watch(isRoisModified, () => {
  if (isRoisModified.value) {
    const [width, height] = getCanvasSize();
    canvasContext.clearRect(0, 0, width, height);
    refreshCanvas();
    isRoisModified.value = false;

    // const roisPoints = rois.map(roi => roi.getPoints());
    const roisPoints = rois[0].getPoints();  // only red

    emits('onRoisModified', roisPoints);
  }
});

onMounted(() => {
  if (roiCanvas.value)
    canvasContext = roiCanvas.value.getContext('2d');
});
</script>

<template>
  <canvas
    ref="roiCanvas"
    class="m-0 p-0"
    @mousedown="onMouseDown"
    @mousemove="onMouseMove"
    @mouseup="onMouseUp"
    @keydown="onKeyDown"
    tabindex="0"
    :style="{ cursor: mouseStyle }"
  ></canvas>
</template>

<style scoped>
</style>