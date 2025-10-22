<template>
    <div class="flex flex-col gap-4">
      <h3>Did this doc help?</h3>
      <div class="flex gap-2">
        <button
          v-for="option in [true, false]"
          :key="option"
          class="feedback__button button button--secondary"
          :class="{ 'feedback__button--active': vote === option }"
          :aria-label="option ? 'Yes' : 'No'"
          :value="option"
          :disabled="isSubmitting"
          @click="handleVote(option)"
        >
          {{ option ? 'Yes' : 'No' }}
        </button>
      </div>

      <p v-if="vote !== null" class="feedback__reply text-sm text-terciary flex">
        Thank you! We received your feedback.
      </p>

      <form
        v-if="vote === false"
        class="flex flex-col gap-2 w-full"
        @submit.prevent="handleSubmit"
      >
        <label for="feedback-message">Can you tell us more?</label>
        <textarea
          id="feedback-message"
          v-model="message"
          class="bg-secondary rounded-md border border-brand-saturated/40 py-2 px-3"
          :disabled="isSubmitting"
        ></textarea>
        <div class="flex gap-3 justify-end">
          <button type="button" class="button button--secondary" @click="handleCancel"  :disabled="isSubmitting">
            Cancel
          </button>
          <button type="submit" class="button button--primary" :disabled="isSubmitting">Send</button>
        </div>
      </form>
    </div>
</template>

<script setup>
  import { ref } from 'vue';

  const vote = ref(null);
  const message = ref('');
  const feedbackId = ref(null);
  const isSubmitting = ref(false);

  function handleVote(val) {
    if (isSubmitting.value) { return };

    vote.value = val;
    isSubmitting.value = true;

    fetch('/.netlify/functions/feedback-create', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        pageUrl: window.location.href,
        feedbackId: feedbackId.value,
        vote: val
      })
    })
      .then((res) => res.json())
      .then((data) => {
        feedbackId.value ||= data.feedbackId;
        console.log('create callback')
        console.log(`id: ${feedbackId.value}`)
      })
      .catch((err) => console.error('Feedback error:', err))
      .finally(() => { isSubmitting.value = false; });
  }

  function handleSubmit() {
    if (isSubmitting.value) { return };

    isSubmitting.value = true;

    fetch('/.netlify/functions/feedback-update', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        pageUrl: window.location.href,
        feedbackId: feedbackId.value,
        message: message.value
      })
    })
      .then((res) => res.json())
      .catch((err) => console.error('Feedback error:', err))
      .finally(() => { isSubmitting.value = false; });
    resetForm();
  }

  function handleCancel() {
    resetForm();
  }

  function resetForm() {
    message.value = '';
    vote.value = null;
  }
</script>

<style scoped>
.feedback__button:disabled {
  @apply !text-gray-500;
}
</style>