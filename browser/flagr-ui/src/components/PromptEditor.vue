<template>
    <div class="context-input-group">
        <el-input
            type="textarea"
            :value="promptText" 
            @input="onPromptInput"
            placeholder="Enter prompt"
            :rows="10"
            class="context-text-input"
        ></el-input>

        <div
            v-if="isModified"
            class="prompt-save-container"
        >
            <el-input
                :value="currentNewPromptName" 
                @input="onNewPromptNameInput"
                placeholder="Enter prompt name"
                class="prompt-name-input"
            ></el-input>
            <div class="prompt-actions">
                <el-button
                    type="primary"
                    @click="handleSavePrompt"
                    :disabled="!currentNewPromptName.trim()"
                    >Save New Prompt</el-button
                >
                <el-button @click="handleCancelEdit"
                    >Cancel</el-button
                >
            </div>
        </div>
    </div>
</template>

<script>
export default {
    name: 'PromptEditor',
    props: {
        promptText: {
            type: String,
            default: ''
        },
        originalPromptText: {
            type: String,
            default: ''
        },
        // Allow parent to control initial newPromptName if needed, though typically it's internal
        newPromptName: {
            type: String,
            default: ''
        },
        // Explicit prop to show modification state, derived in parent
        isModified: {
            type: Boolean,
            default: false,
        }
    },
    data() {
        return {
            // Internal state for the new prompt name if parent doesn't manage it via prop
            currentNewPromptName: this.newPromptName 
        }
    },
    watch: {
        newPromptName(val) {
            // Keep internal state in sync if parent changes the prop
            this.currentNewPromptName = val;
        }
    },
    methods: {
        onPromptInput(value) {
            this.$emit('update:promptText', value);
            // Parent will determine isModified state based on this update and originalPromptText
            this.$emit('input', value); // For simpler @input handling if preferred by parent
        },
        onNewPromptNameInput(value) {
            this.currentNewPromptName = value;
            this.$emit('update:newPromptName', value);
        },
        handleSavePrompt() {
            this.$emit('save-prompt', { name: this.currentNewPromptName, content: this.promptText });
        },
        handleCancelEdit() {
            this.$emit('cancel-edit');
        }
    }
};
</script>

<style scoped lang="less">
/* Copied from Flag.vue - adjust if necessary */
.context-input-group {
    width: 100%;
    /* margin-top: 20px; Removed as it was part of header-row in Flag.vue */
}

.context-text-input {
    width: 100%;
}

.prompt-save-container {
    margin-top: 10px; /* Reduced from 20px to be more self-contained */
    display: flex;
    gap: 10px;
    align-items: center; /* Align items vertically */
}

.prompt-name-input {
    width: 200px;
}

.prompt-actions {
    display: flex;
    gap: 10px;
}
</style> 