<template>
  <div class="relative inline-flex" ref="container">
    <div class="inline-flex items-stretch rounded-lg bg-secondary text-sm text-terciary">
      <button
        class="flex items-center gap-2 px-2 py-1.5 hover:bg-hover-component/100 transition-colors rounded-l-lg text-xs border border-primary/10 text-secondary"
        @click="copyForLLM(); closeMenu()"
      >
        <svg v-if="copyState !== 'success'" viewBox="0 0 24 24" class="w-4 h-4" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
          <path d="M5 22C4.45 22 3.97917 21.8042 3.5875 21.4125C3.19583 21.0208 3 20.55 3 20V6H5V20H16V22H5ZM9 18C8.45 18 7.97917 17.8042 7.5875 17.4125C7.19583 17.0208 7 16.55 7 16V4C7 3.45 7.19583 2.97917 7.5875 2.5875C7.97917 2.19583 8.45 2 9 2H18C18.55 2 19.0208 2.19583 19.4125 2.5875C19.8042 2.97917 20 3.45 20 4V16C20 16.55 19.8042 17.0208 19.4125 17.4125C19.0208 17.8042 18.55 18 18 18H9ZM9 16H18V4H9V16Z" fill="currentColor"></path>
        </svg>
        <svg v-else class="w-4 h-4" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="rgb(var(--color-semantic-green-primary))" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <path d="M20 6 9 17l-5-5"></path>
      </svg>
        Copy page
      </button>
      <button
        class="flex items-center px-2 py-1.5 hover:bg-hover-component/100 transition-colors rounded-r-lg border border-l-0 border-primary/10"
        @click="toggleMenu"
        @keydown="handleTriggerKeydown"
        :aria-expanded="isOpen.toString()"
        aria-haspopup="true"
      >
        <svg
          class="w-3 h-3 transition-transform"
          :class="{ 'rotate-180': isOpen }"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke-width="2"
          stroke="currentColor"
        >
          <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
        </svg>
      </button>
    </div>

    <Transition
      enter-active-class="transition ease-out duration-100"
      enter-from-class="opacity-0 scale-95"
      enter-to-class="opacity-100 scale-100"
      leave-active-class="transition ease-in duration-75"
      leave-from-class="opacity-100 scale-100"
      leave-to-class="opacity-0 scale-95"
    >
      <ul
        v-show="isOpen"
        class="absolute left-0 lg:left-auto lg:right-0 top-9 z-10 min-w-64 list-none ml-0 flex flex-col border rounded-lg bg-secondary border-primary/10 shadow-lg gap-0"
        role="menu"
      >
        <li class="px-1 pt-1">
          <button
            role="menuitem"
            class="flex items-center gap-3 w-full px-3 py-2.5 text-left rounded-md hover:bg-hover-component/100 transition-colors text-primary"
            @click="copyForLLM(); closeMenu()"
          >
            <span class="flex items-center justify-center w-7 h-7 rounded-md border border-primary/10 bg-primary/5 shrink-0 text-primary">
              <svg viewBox="0 0 24 24" class="w-3.5 h-3.5" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M5 22C4.45 22 3.97917 21.8042 3.5875 21.4125C3.19583 21.0208 3 20.55 3 20V6H5V20H16V22H5ZM9 18C8.45 18 7.97917 17.8042 7.5875 17.4125C7.19583 17.0208 7 16.55 7 16V4C7 3.45 7.19583 2.97917 7.5875 2.5875C7.97917 2.19583 8.45 2 9 2H18C18.55 2 19.0208 2.19583 19.4125 2.5875C19.8042 2.97917 20 3.45 20 4V16C20 16.55 19.8042 17.0208 19.4125 17.4125C19.0208 17.8042 18.55 18 18 18H9ZM9 16H18V4H9V16Z" fill="currentColor"></path>
              </svg>
            </span>
            <span class="flex flex-col">
              <span class="text-xs font-medium">Copy for LLM</span>
              <span class="text-xs text-terciary">Copy page as Markdown for LLMs</span>
            </span>
          </button>
        </li>

        <li class="px-1 pt-1">
          <a
            role="menuitem"
            :href="mdUrl"
            target="_blank"
            rel="noopener"
            class="flex items-center gap-3 w-full px-3 py-2.5 text-left no-underline hover:no-underline text-primary rounded-md hover:bg-hover-component/100 transition-colors"
            @click="closeMenu"
          >
            <span class="flex items-center justify-center w-7 h-7 rounded-md border border-primary/10 bg-primary/5 shrink-0 text-primary">
              <svg class="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M16 15L19 12L17.95 10.925L16.75 12.125V9H15.25V12.125L14.05 10.925L13 12L16 15ZM4 20C3.45 20 2.97917 19.8042 2.5875 19.4125C2.19583 19.0208 2 18.55 2 18V6C2 5.45 2.19583 4.97917 2.5875 4.5875C2.97917 4.19583 3.45 4 4 4H20C20.55 4 21.0208 4.19583 21.4125 4.5875C21.8042 4.97917 22 5.45 22 6V18C22 18.55 21.8042 19.0208 21.4125 19.4125C21.0208 19.8042 20.55 20 20 20H4ZM4 18H20V6H4V18ZM5.5 15H7V10.5H8V13.5H9.5V10.5H10.5V15H12V10C12 9.71667 11.9042 9.47917 11.7125 9.2875C11.5208 9.09583 11.2833 9 11 9H6.5C6.21667 9 5.97917 9.09583 5.7875 9.2875C5.59583 9.47917 5.5 9.71667 5.5 10V15Z" fill="currentColor"/>
              </svg>
            </span>
            <span class="flex flex-col">
              <span class="text-xs font-medium flex items-center gap-1">
                View as Markdown
                <svg class="w-3 h-3" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 6H5.25A2.25 2.25 0 0 0 3 8.25v10.5A2.25 2.25 0 0 0 5.25 21h10.5A2.25 2.25 0 0 0 18 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25" />
                </svg>
              </span>
              <span class="text-xs text-terciary">Open this page as Markdown</span>
            </span>
          </a>
        </li>

        <li class="px-1 pt-1">
          <a
            role="menuitem"
            :href="chatgptUrl"
            target="_blank"
            rel="noopener"
            class="flex items-center gap-3 w-full px-3 py-2.5 text-left no-underline hover:no-underline text-primary no-icon rounded-md hover:bg-hover-component/100 transition-colors"
            @click="closeMenu"
          >
            <span class="flex items-center justify-center w-7 h-7 rounded-md border border-primary/10 bg-primary/5 shrink-0 text-primary">
              <svg class="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M20.6863 10.1842C20.913 9.51077 20.9914 8.79737 20.9163 8.09166C20.8411 7.38595 20.6142 6.70417 20.2506 6.09188C19.7116 5.16641 18.8886 4.43369 17.9002 3.99936C16.9118 3.56502 15.8091 3.45153 14.7511 3.67522C14.15 3.0157 13.3835 2.52379 12.5287 2.24891C11.6739 1.97402 10.7609 1.92585 9.8812 2.10921C9.00155 2.29258 8.18629 2.70103 7.51732 3.29355C6.84834 3.88606 6.3492 4.64178 6.07002 5.4848C5.36516 5.62738 4.69927 5.91671 4.11686 6.33346C3.53444 6.75021 3.04891 7.28479 2.69271 7.90146C2.14784 8.8254 1.91496 9.89632 2.02775 10.9594C2.14054 12.0225 2.59315 13.0226 3.32015 13.8153C3.09261 14.4884 3.01342 15.2017 3.08787 15.9074C3.16232 16.6131 3.38869 17.295 3.75185 17.9075C4.29155 18.8333 5.11531 19.5662 6.10441 20.0005C7.09351 20.4349 8.19686 20.5482 9.25547 20.3243C9.73301 20.8547 10.3198 21.2786 10.9766 21.5675C11.6334 21.8565 12.3452 22.0039 13.0644 21.9999C14.1488 22.0009 15.2055 21.662 16.0819 21.032C16.9584 20.402 17.6092 19.5137 17.9405 18.4951C18.6452 18.3523 19.311 18.0628 19.8934 17.6461C20.4758 17.2293 20.9614 16.6949 21.3178 16.0784C21.8562 15.1558 22.0851 14.0889 21.9717 13.0302C21.8582 11.9716 21.4083 10.9754 20.6863 10.1842ZM13.0644 20.6909C12.1763 20.6923 11.316 20.3853 10.6344 19.8236L10.7542 19.7566L14.791 17.4581C14.8915 17.4 14.9749 17.3171 15.0331 17.2175C15.0912 17.118 15.1221 17.0052 15.1228 16.8904V11.2763L16.8293 12.2501C16.8377 12.2543 16.845 12.2605 16.8506 12.268C16.8562 12.2755 16.8599 12.2842 16.8614 12.2934V16.9456C16.8593 17.9383 16.4585 18.8897 15.7469 19.5916C15.0353 20.2936 14.0708 20.6888 13.0644 20.6909ZM4.90291 17.2531C4.4575 16.4945 4.29758 15.6052 4.45127 14.7417L4.57123 14.8127L8.61197 17.1112C8.71195 17.1691 8.82578 17.1996 8.9417 17.1996C9.05763 17.1996 9.17145 17.1691 9.27143 17.1112L14.2075 14.3041V16.2478C14.207 16.2578 14.2043 16.2677 14.1994 16.2766C14.1946 16.2854 14.1877 16.2931 14.1795 16.299L10.0907 18.6251C9.21815 19.1209 8.18175 19.255 7.20908 18.9977C6.23642 18.7405 5.40699 18.113 4.90291 17.2531ZM3.8398 8.57963C4.28829 7.8161 4.9962 7.23374 5.8382 6.93563V11.6666C5.83668 11.7809 5.86629 11.8935 5.92393 11.9927C5.98157 12.0918 6.06513 12.1739 6.1659 12.2304L11.078 15.0256L9.37137 15.9994C9.36214 16.0042 9.35184 16.0067 9.34138 16.0067C9.33093 16.0067 9.32063 16.0042 9.31139 15.9994L5.2307 13.6773C4.35975 13.1793 3.72435 12.3611 3.46366 11.402C3.20296 10.4429 3.33822 9.42093 3.8398 8.55996V8.57963ZM17.8606 11.7928L12.9325 8.96996L14.6351 7.99996C14.6444 7.99512 14.6547 7.9926 14.6651 7.9926C14.6756 7.9926 14.6859 7.99512 14.6951 7.99996L18.7758 10.326C19.3998 10.6812 19.9084 11.204 20.2424 11.8336C20.5764 12.4632 20.7219 13.1735 20.662 13.8816C20.602 14.5897 20.3391 15.2664 19.904 15.8326C19.4688 16.3989 18.8793 16.8313 18.2043 17.0795V12.3485C18.2008 12.2344 18.1672 12.1232 18.1069 12.0257C18.0467 11.9283 17.9618 11.8481 17.8606 11.7928ZM19.5592 9.27354L19.4393 9.20254L15.4065 6.88438C15.306 6.82615 15.1914 6.79545 15.0748 6.79545C14.9581 6.79545 14.8436 6.82615 14.743 6.88438L9.8111 9.69137V7.7478C9.81005 7.73791 9.81172 7.72794 9.81595 7.71891C9.82017 7.70989 9.82678 7.70217 9.83509 7.69655L13.9158 5.37439C14.5412 5.01899 15.2563 4.84659 15.9774 4.87735C16.6985 4.90812 17.3958 5.14078 17.9878 5.54812C18.5798 5.95546 19.042 6.52065 19.3202 7.17757C19.5985 7.8345 19.6815 8.55601 19.5593 9.25771L19.5592 9.27354ZM8.87969 12.7191L7.17317 11.7493C7.16464 11.7442 7.15733 11.7374 7.15179 11.7292C7.14624 11.721 7.14258 11.7118 7.14107 11.702V7.0618C7.14201 6.34994 7.34837 5.65306 7.73603 5.05264C8.12369 4.45221 8.67662 3.97305 9.33018 3.67117C9.98374 3.3693 10.7109 3.25719 11.4267 3.34796C12.1425 3.43872 12.8172 3.72861 13.3722 4.18372L13.2522 4.25081L9.21551 6.54913C9.11504 6.60726 9.03162 6.69016 8.97346 6.7897C8.91529 6.88924 8.88438 7.00199 8.88375 7.11688L8.87969 12.7191ZM9.80696 10.748L12.0052 9.49812L14.2075 10.748V13.2474L12.0132 14.4972L9.81102 13.2474L9.80696 10.748Z" fill="currentColor"/>
              </svg>
            </span>
            <span class="flex flex-col">
              <span class="text-xs font-medium flex items-center gap-1">
                Open in ChatGPT
                <svg class="w-3 h-3" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 6H5.25A2.25 2.25 0 0 0 3 8.25v10.5A2.25 2.25 0 0 0 5.25 21h10.5A2.25 2.25 0 0 0 18 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25" />
                </svg>
              </span>
              <span class="text-xs text-terciary">Get insights from ChatGPT</span>
            </span>
          </a>
        </li>

        <li class="px-1 pt-1 pb-1">
          <a
            role="menuitem"
            :href="claudeUrl"
            target="_blank"
            rel="noopener"
            class="flex items-center gap-3 w-full px-3 py-2.5 text-left no-underline hover:no-underline text-primary no-icon rounded-md hover:bg-hover-component/100 transition-colors"
            @click="closeMenu"
          >
            <span class="flex items-center justify-center w-7 h-7 rounded-md border border-primary/10 bg-primary/5 shrink-0 text-primary">
              <svg class="w-3.5 h-3.5" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M4.03188 9.88255L6.60172 8.62367L6.64494 8.51434L6.60172 8.45352H6.47649L6.04701 8.43042L4.57865 8.39577L3.3052 8.34957L2.07142 8.29182L1.761 8.23408L1.46997 7.89915L1.49996 7.73207L1.761 7.57884L2.13492 7.60733L2.96126 7.65661L4.2012 7.7313L5.10074 7.77749L6.43328 7.89838H6.64494L6.67492 7.82369L6.60261 7.77749L6.54616 7.7313L5.26301 6.97212L3.87402 6.16983L3.14646 5.70785L2.75313 5.47379L2.5547 5.25435L2.46916 4.77544L2.82633 4.43204L3.30608 4.46052L3.42866 4.48901L3.91459 4.81548L4.95258 5.5169L6.30805 6.38849L6.50648 6.53248L6.58585 6.4832L6.59555 6.44855L6.50648 6.31843L5.76921 5.15503L4.98256 3.9716L4.63245 3.48114L4.53985 3.18702C4.50722 3.06614 4.48341 2.9645 4.48341 2.84054L4.88996 2.35855L5.11485 2.29541L5.65721 2.35855L5.88562 2.53179L6.22251 3.20473L6.7684 4.26419L7.61502 5.70477L7.86284 6.1321L7.99512 6.52786L8.04451 6.64874H8.13005V6.57944L8.19972 5.76791L8.32848 4.77159L8.45371 3.48961L8.49692 3.1285L8.70152 2.69579L9.10807 2.46172L9.42556 2.59415L9.6866 2.92061L9.65044 3.13158L9.49523 4.01241L9.19097 5.39217L8.99254 6.31612H9.10807L9.24036 6.20062L9.77567 5.58004L10.6752 4.59835L11.0721 4.20875L11.5351 3.77834L11.8323 3.57354H12.394L12.8076 4.1102L12.6224 4.66456L12.0439 5.30517L11.5642 5.84799L10.8763 6.65644L10.4468 7.3032L10.4865 7.35479L10.5888 7.34632L12.1427 7.05759L12.9822 6.92515L13.9841 6.77501L14.4374 6.9598L14.4868 7.14767L14.3086 7.53188L13.2371 7.76287L11.9804 7.9823L10.109 8.36882L10.0861 8.38345L10.1126 8.41194L10.9556 8.48123L11.3163 8.49817H12.1991L13.843 8.6052L14.2725 8.85312L14.53 9.15649L14.4868 9.38747L13.8253 9.68159L12.9329 9.4968L10.8498 9.06409L10.1355 8.90856H10.0367V8.96014L10.632 9.46832L11.7229 10.3284L13.089 11.4371L13.1586 11.7112L12.9831 11.9276L12.7979 11.9045L11.5977 11.116L11.1347 10.7611L10.0861 9.99035H10.0164V10.0712L10.2581 10.3799L11.5342 12.0546L11.6003 12.5682L11.5077 12.7352L11.177 12.8361L10.8137 12.7784L10.0667 11.8629L9.29592 10.8319L8.67418 9.90796L8.59834 9.94569L8.23147 13.3959L8.0595 13.5722L7.66264 13.7046L7.33193 13.4852L7.15644 13.1302L7.33193 12.4288L7.54359 11.5133L7.71556 10.7857L7.87077 9.88178L7.96337 9.5815L7.9572 9.56148L7.88136 9.56995L7.10088 10.5054L5.91385 11.906L4.97463 12.7837L4.74974 12.8615L4.35994 12.6852L4.3961 12.3703L4.61393 12.09L5.91385 10.6463L6.69785 9.75166L7.20406 9.23502L7.20053 9.16033H7.17055L3.71792 11.1176L3.10324 11.1869L2.83867 10.9705L2.8713 10.6155L2.99653 10.5001L4.03452 9.87639L4.031 9.87947L4.03188 9.88255Z" fill="currentColor"/>
              </svg>
            </span>
            <span class="flex flex-col">
              <span class="text-xs font-medium flex items-center gap-1">
                Open in Claude
                <svg class="w-3 h-3" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 6H5.25A2.25 2.25 0 0 0 3 8.25v10.5A2.25 2.25 0 0 0 5.25 21h10.5A2.25 2.25 0 0 0 18 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25" />
                </svg>
              </span>
              <span class="text-xs text-tertiary">Get insights from Claude</span>
            </span>
          </a>
        </li>
      </ul>
    </Transition>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue';

const props = defineProps({
  mdUrl: {
    type: String,
    required: true,
  },
});

const isOpen = ref(false);
const copyState = ref('idle');
const container = ref(null);

const fullMdUrl = computed(() => {
  return new URL(props.mdUrl, window.location.origin).href;
});

const chatgptUrl = computed(() => {
  return `https://chatgpt.com/?q=Read+this+page+and+answer+my+questions+based+on+the+content:+${encodeURIComponent(fullMdUrl.value)}`;
});

const claudeUrl = computed(() => {
  return `https://claude.ai/new?q=Read+this+page+and+answer+my+questions+based+on+the+content:+${encodeURIComponent(fullMdUrl.value)}`;
});

function toggleMenu() {
  isOpen.value = !isOpen.value;
}

function closeMenu() {
  isOpen.value = false;
}

function handleTriggerKeydown(e) {
  if (['Enter', ' ', 'ArrowDown'].includes(e.key)) {
    e.preventDefault();
    isOpen.value = true;
  }
}

function handleClickOutside(e) {
  if (container.value && !container.value.contains(e.target)) {
    closeMenu();
  }
}

function handleEscape(e) {
  if (e.key === 'Escape' && isOpen.value) {
    closeMenu();
  }
}

async function copyForLLM() {
  copyState.value = 'copying';

  try {
    const res = await fetch(props.mdUrl);
    if (!res.ok) throw new Error('Failed to fetch');

    const text = await res.text();
    await navigator.clipboard.writeText(text);

    copyState.value = 'success';
    setTimeout(() => {
      copyState.value = 'idle';
    }, 1500);
  } catch (err) {
    console.error('Copy failed:', err);
    copyState.value = 'error';
    setTimeout(() => {
      copyState.value = 'idle';
    }, 2000);
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside);
  document.addEventListener('keydown', handleEscape);
});

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickOutside);
  document.removeEventListener('keydown', handleEscape);
});
</script>
