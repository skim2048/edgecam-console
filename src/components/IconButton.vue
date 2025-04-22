<script setup>
import { ref, computed } from 'vue';

const props = defineProps({
  btnWidth: { type: Number, default: 27 },
  btnHeight: { type: Number, default: 27 },
  btnPadding: { type: Number, default: 0 },
  btnDisabled: { type: Boolean, default: false },
  btnBackgroundColor: { type: String, default: 'transparent' },
  iconHref: { type: String, default: '/icons.svg#bootstrap' },
  iconPressedHref: { type: String, default: null },
});

const emits = defineEmits([
  'onToggled',
])

const iconPressedHref = computed(() => 
  props.iconPressedHref ? props.iconPressedHref : props.iconHref
);

const state = ref(false);

function onToggled() {
  state.value = !state.value;
  emits('onToggled', state.value);
}
</script>

<template>
  <button
    class="d-flex align-items-center justify-content-center p-0"
    :disabled="props.btnDisabled"
    :style="{ width: `${props.btnWidth}px`,
              height: `${props.btnHeight}px`,
              backgroundColor: `${props.btnBackgroundColor}` }"
    @click="onToggled">
    <svg
      class="bi theme-icon-active"
      :style="{ width: `${props.btnWidth - props.btnPadding}px`,
                height: `${props.btnHeight - props.btnPadding}px` }">
        <use :href="`${ state ? iconPressedHref : props.iconHref }`"/>
    </svg>
  </button>
</template>

<style scoped>
button:hover {
  color: rgba(var(--bs-emphasis-color-rgb), .50);
  background-color: var(--bs-tertiary-bg);
}
</style>