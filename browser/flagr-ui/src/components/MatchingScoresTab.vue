<template>
    <div>
        <div class="matching-scores-explanation">
            <p><strong><em>This tool compares your subscribed user categories with AI-generated categories from your selected LLM model. Note: Using different LLM models for categorization may cause mismatches between existing and new categories.</em></strong></p>
        </div>

        <div class="header-controls">
            <el-autocomplete
                v-model="userSearchInput"
                :fetch-suggestions="debounceSearchUsers"
                placeholder="Search user by username"
                :trigger-on-focus="false"
                @select="handleUserSelect"
                value-key="username"
                class="user-select"
            >
                <template slot-scope="{ item }">
                    <div class="user-suggestion-item">
                        <span>{{ item.username }}</span>
                        <span
                            style="
                                float: right;
                                color: #8492a6;
                                font-size: 13px;
                            "
                        >
                            {{ item.firstName }}
                        </span>
                    </div>
                </template>
            </el-autocomplete>

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
                v-model="selectedProvider"
                placeholder="Select LLM Provider"
                class="model-select"
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

            <el-button
                class="config-button"
                @click="openConfig"
                type="primary"
                plain
            >
                <i class="el-icon-setting"></i> Weights
            </el-button>
        </div>

        <!-- User Data Display -->
        <user-data-display
            :user="selectedUser"
            :show-data="showUserData"
            :chain-data="chainData"
            @close="showUserData = false"
            :initially-expanded="true"
        ></user-data-display>

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
                    :prompt-text.sync="promptText"
                    :original-prompt-text="originalPromptText"
                    :new-prompt-name.sync="newPromptName"
                    :is-modified="isPromptModified"
                    @input="handlePromptInput"
                    @save-prompt="savePrompt"
                    @cancel-edit="cancelPromptEdit"
                ></prompt-editor>
            </div>
        </div>

        <el-card class="variants-container">
            <div slot="header" class="clearfix">
                <div class="variants-header">
                    <h2>Variants</h2>
                    <el-button 
                        type="primary" 
                        size="small" 
                        icon="el-icon-plus"
                        @click="$emit('add-variant')"
                    >
                        Add Variant
                    </el-button>
                </div>
            </div>
            <div
                class="variants-container-inner"
                v-if="variants.length"
            >
                <variant-card
                    v-for="(variant, index) in variants" 
                    :key="variant.id"
                    :variant.sync="variants[index]" 
                    :is-evaluating-any-other="isAnyVariantEvaluating && !variant.evaluating"
                    :is-simulating="isSimulating"
                    @save="$emit('save-variant', $event)"
                    @delete="$emit('delete-variant', $event)"
                    @apply-config="$emit('apply-config-to-variant', $event)"
                    @evaluate="$emit('evaluate-variant', $event)"
                    @attachment-error="$emit('attachment-error')" 
                    @show-message="$emit('show-message', $event)"
                ></variant-card>
            </div>

            <div
                v-if="variants.length >= 2"
                class="ab-test-simulation"
            >
                <el-button
                    type="primary"
                    @click="$emit('run-ab-test')"
                    :loading="isSimulating"
                    :disabled="isSimulating || isAnyVariantEvaluating"
                    class="width--full"
                >
                    Run A/B Test Simulation
                </el-button>

                <div
                    v-if="abTestResult"
                    class="simulation-result"
                >
                    <div class="simulation-header">
                        <h4>A/B Test Simulation Result</h4>
                    </div>
                    <pre class="simulation-json">{{ JSON.stringify(abTestResult, null, 2) }}</pre>
                </div>
            </div>
        </el-card>

        <spinner v-if="!loaded"></spinner>
    </div>
</template>

<script>
import ChainDataDisplay from './ChainDataDisplay.vue';
import UserDataDisplay from './UserDataDisplay.vue';
import PromptEditor from './PromptEditor.vue';
import VariantCard from './VariantCard.vue';
import Spinner from './Spinner.vue';

export default {
    name: 'MatchingScoresTab',
    components: {
        ChainDataDisplay,
        UserDataDisplay,
        PromptEditor,
        VariantCard,
        Spinner,
    },
    props: {
        userSearchInput: {
            type: String,
            default: '',
        },
        debounceSearchUsers: {
            type: Function,
            required: true,
        },
        selectedUser: {
            type: Object,
            default: null,
        },
        showUserData: {
            type: Boolean,
            default: false,
        },
        chainId: {
            type: String,
            default: '',
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
        dagText: {
            type: String,
            default: '',
        },
        selectedProvider: {
            type: String,
            default: '',
        },
        providers: {
            type: Array,
            default: () => [],
        },
        selectedPrompt: {
            type: String,
            default: '',
        },
        prompts: {
            type: Array,
            default: () => [],
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
        variants: {
            type: Array,
            default: () => [],
        },
        isAnyVariantEvaluating: {
            type: Boolean,
            default: false,
        },
        isSimulating: {
            type: Boolean,
            default: false,
        },
        abTestResult: {
            type: Object,
            default: null,
        },
        loaded: {
            type: Boolean,
            default: false,
        },
    },
    methods: {
        handleUserSelect(user) {
            this.$emit('user-select', user);
        },
        handleChainIdChange(value) {
            this.$emit('update:chain-id', value);
        },
        handleTweetUrlChange(value) {
            this.$emit('update:dag-text', value);
        },
        handleProviderChange() {
            this.$emit('provider-change', this.selectedProvider);
        },
        handlePromptChange() {
            this.$emit('prompt-change', this.selectedPrompt);
        },
        openConfig() {
            this.$emit('open-config');
        },
        handlePromptInput() {
            this.$emit('prompt-input');
        },
        savePrompt() {
            this.$emit('save-prompt');
        },
        cancelPromptEdit() {
            this.$emit('cancel-prompt-edit');
        },
    },
};
</script>

<style scoped>
.matching-scores-explanation {
    text-align: center;
    margin-bottom: 20px;
    padding: 15px;
    background-color: #f5f7fa;
    border-radius: 4px;
}

.header-controls {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    margin-bottom: 15px;
}

.user-select,
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

.config-button {
    min-width: 100px;
}

.user-suggestion-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.header-row {
    margin-bottom: 15px;
}

.context-input-group {
    width: 100%;
}

.variants-container {
    margin-top: 20px;
}

.variants-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.variants-container-inner {
    margin: 15px 0;
}

.ab-test-simulation {
    margin-top: 20px;
    padding-top: 15px;
    border-top: 1px solid #ebeef5;
}

.simulation-result {
    margin-top: 15px;
}

.simulation-header {
    margin-bottom: 10px;
}

.simulation-json {
    background-color: #f5f7fa;
    padding: 10px;
    border-radius: 4px;
    font-family: monospace;
    font-size: 12px;
    white-space: pre-wrap;
    word-wrap: break-word;
    max-height: 300px;
    overflow-y: auto;
}
</style> 