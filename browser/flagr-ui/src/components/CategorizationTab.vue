<template>
    <div class="categorization-container">
        <div class="header-controls">
            <el-input
                :value="chainId"
                placeholder="Enter Chain ID"
                class="chain-id-input"
                @input="handleChainIdChange"
            ></el-input>

            <div class="dag-input-group">
                <el-input
                    :value="dagText"
                    placeholder="Enter tweet url"
                    class="dag-text-input"
                    @input="handleTweetUrlChange"
                ></el-input>
            </div>

            <el-select
                v-model="selectedProviders"
                placeholder="Select LLM Providers"
                class="model-select"
                multiple
                @change="handleProviderChange"
            >
                <el-option
                    v-for="item in providers"
                    :key="item.value"
                    :label="item.label"
                    :value="item.value"
                ></el-option>
            </el-select>

            <el-select
                v-model="selectedPrompt"
                placeholder="Select Prompt"
                class="prompt-select"
                @change="handlePromptChange"
            >
                <el-option
                    v-for="item in prompts"
                    :key="item._id"
                    :label="item.name"
                    :value="item._id"
                ></el-option>
            </el-select>
        </div>

        <!-- Chain Data Display -->
        <chain-data-display
            :chain-id="chainId"
            :chain-data="chainData"
            :is-loading="chainDataLoading"
            :show-data="showChainData"
            @close="showChainData = false"
            :initially-expanded="true"
        ></chain-data-display>

        <div class="header-row">
            <div class="context-input-group">
                <prompt-editor
                    :prompt-text="promptText"
                    :original-prompt-text="originalPromptText"
                    :new-prompt-name="newPromptName"
                    :is-modified="isPromptModified"
                    @update:promptText="handlePromptTextUpdate"
                    @update:newPromptName="handleNewPromptNameUpdate"
                    @input="handlePromptInput"
                    @save-prompt="savePrompt"
                    @cancel-edit="cancelPromptEdit"
                ></prompt-editor>
            </div>
        </div>

        <div class="submit-container">
            <div class="categorization-controls">
                <el-button
                    type="primary"
                    @click="runCategorization"
                    :loading="isCategorizing"
                    class="width--full"
                >
                    Run Categorization
                </el-button>
                
                <el-button
                    v-if="categorizationRuns.length > 0"
                    type="danger"
                    plain
                    @click="clearCategorizationHistory"
                    class="clear-history-button"
                >
                    Clear History
                </el-button>
            </div>

            <categorization-results-table
                v-if="categorizationRuns.length"
                :categorization-runs="categorizationRuns"
                :expanded-runs.sync="expandedRuns"
                :expanded-json.sync="expandedJson"
                @expand-all="expandAllRuns"
                @collapse-all="collapseAllRuns"
                @run-expand="handleRunExpand"
            ></categorization-results-table>
        </div>
    </div>
</template>

<script>
import ChainDataDisplay from './ChainDataDisplay.vue';
import PromptEditor from './PromptEditor.vue';
import CategorizationResultsTable from './CategorizationResultsTable.vue';

export default {
    name: 'CategorizationTab',
    components: {
        ChainDataDisplay,
        PromptEditor,
        CategorizationResultsTable,
    },
    props: {
        chainId: {
            type: String,
            default: '',
        },
        dagText: {
            type: String,
            default: '',
        },
        selectedProviders: {
            type: Array,
            default: () => [],
        },
        selectedPrompt: {
            type: String,
            default: '',
        },
        providers: {
            type: Array,
            default: () => [],
        },
        prompts: {
            type: Array,
            default: () => [],
        },
        chainData: {
            type: Object,
            default: null,
        },
        chainDataLoading: {
            type: Boolean,
            default: false,
        },
        showChainData: {
            type: Boolean,
            default: false,
        },
        promptText: {
            type: String,
            default: '',
        },
        originalPromptText: {
            type: String,
            default: '',
        },
        newPromptName: {
            type: String,
            default: '',
        },
        isPromptModified: {
            type: Boolean,
            default: false,
        },
        isCategorizing: {
            type: Boolean,
            default: false,
        },
        categorizationRuns: {
            type: Array,
            default: () => [],
        },
        expandedRuns: {
            type: Array,
            default: () => [],
        },
        expandedJson: {
            type: Array,
            default: () => [],
        },
    },
    methods: {
        handleChainIdChange(value) {
            this.$emit('update:chain-id', value);
        },
        handleTweetUrlChange(value) {
            this.$emit('update:dag-text', value);
        },
        handleProviderChange() {
            this.$emit('provider-change', this.selectedProviders);
        },
        handlePromptChange() {
            this.$emit('prompt-change', this.selectedPrompt);
        },
        handlePromptInput(value) {
            this.$emit('prompt-input', value);
        },
        savePrompt(payload) {
            this.$emit('save-prompt', payload);
        },
        cancelPromptEdit() {
            this.$emit('cancel-prompt-edit');
        },
        runCategorization() {
            this.$emit('run-categorization');
        },
        clearCategorizationHistory() {
            this.$emit('clear-categorization-history');
        },
        expandAllRuns() {
            this.$emit('expand-all-runs');
        },
        collapseAllRuns() {
            this.$emit('collapse-all-runs');
        },
        handleRunExpand(expandedNames) {
            this.$emit('run-expand', expandedNames);
        },
        handlePromptTextUpdate(value) {
            this.$emit('update:prompt-text', value);
        },
        handleNewPromptNameUpdate(value) {
            this.$emit('update:new-prompt-name', value);
        },
    },
};
</script>

<style scoped>
.categorization-container {
    padding: 0;
}

.header-controls {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    margin-bottom: 15px;
}

.chain-id-input,
.dag-text-input,
.model-select,
.prompt-select {
    min-width: 200px;
    flex: 1;
}

.dag-input-group {
    min-width: 250px;
    flex: 1;
}

.header-row {
    margin-bottom: 15px;
}

.context-input-group {
    width: 100%;
}

.submit-container {
    margin-top: 10px;
}

.categorization-controls {
    display: flex;
    gap: 10px;
    margin-bottom: 15px;
}

.clear-history-button {
    min-width: 120px;
}
</style> 