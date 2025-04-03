<template>
    <el-drawer
        title="Configuration Settings"
        :visible.sync="drawerVisible"
        direction="rtl"
        size="50%"
    >
        <div class="configuration-drawer">
            <el-form :model="config" label-width="180px">
                <!-- Add Weight Configuration Toggle -->
                <el-form-item label="Enable Configuration">
                    <el-switch
                        v-model="weightsEnabled"
                        active-color="#13ce66"
                        inactive-color="#ff4949"
                    ></el-switch>
                </el-form-item>

                <el-collapse v-model="activeNames">
                    <!-- Type Weights -->
                    <el-collapse-item title="Type Weights" name="type_weights">
                        <el-form-item label="Custom">
                            <el-input-number
                                v-model="config.WEIGHTS.TYPE_WEIGHTS.CUSTOM"
                                :step="0.1"
                                :min="0"
                                :max="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                        <el-form-item label="Active Subscribed">
                            <el-input-number
                                v-model="
                                    config.WEIGHTS.TYPE_WEIGHTS
                                        .ACTIVE_SUBSCRIBED
                                "
                                :step="0.1"
                                :min="0"
                                :max="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                        <el-form-item label="Passive Subscribed">
                            <el-input-number
                                v-model="
                                    config.WEIGHTS.TYPE_WEIGHTS
                                        .PASSIVE_SUBSCRIBED
                                "
                                :step="0.1"
                                :min="0"
                                :max="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                        <el-form-item label="Active Unsubscribed">
                            <el-input-number
                                v-model="
                                    config.WEIGHTS.TYPE_WEIGHTS
                                        .ACTIVE_UNSUBSCRIBED
                                "
                                :step="0.1"
                                :min="0"
                                :max="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                        <el-form-item label="Passive Unsubscribed">
                            <el-input-number
                                v-model="
                                    config.WEIGHTS.TYPE_WEIGHTS
                                        .PASSIVE_UNSUBSCRIBED
                                "
                                :step="0.1"
                                :min="0"
                                :max="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                    </el-collapse-item>

                    <!-- Interaction Weights -->
                    <el-collapse-item
                        title="Interaction Weights"
                        name="interaction_weights"
                    >
                        <el-form-item label="Base Multiplier">
                            <el-input-number
                                v-model="
                                    config.WEIGHTS.INTERACTION_WEIGHTS
                                        .BASE_MULTIPLIER
                                "
                                :step="0.1"
                                :min="0"
                                :max="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                        <el-form-item label="Max Boost">
                            <el-input-number
                                v-model="
                                    config.WEIGHTS.INTERACTION_WEIGHTS.MAX_BOOST
                                "
                                :step="0.1"
                                :min="0"
                                :max="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                        <el-form-item label="Recency Factor">
                            <el-input-number
                                v-model="
                                    config.WEIGHTS.INTERACTION_WEIGHTS
                                        .RECENCY_FACTOR
                                "
                                :step="0.01"
                                :min="0"
                                :max="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                    </el-collapse-item>

                    <!-- Thread Weights -->
                    <el-collapse-item
                        title="Thread Weights"
                        name="thread_weights"
                    >
                        <el-form-item label="Base Length">
                            <el-input-number
                                v-model="
                                    config.WEIGHTS.THREAD_WEIGHTS.BASE_LENGTH
                                "
                                :step="0.1"
                                :min="0"
                                :max="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                        <el-form-item label="Optimal Length">
                            <el-input-number
                                v-model="
                                    config.WEIGHTS.THREAD_WEIGHTS.OPTIMAL_LENGTH
                                "
                                :step="0.1"
                                :min="0"
                                :max="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                        <el-form-item label="Max Boost">
                            <el-input-number
                                v-model="
                                    config.WEIGHTS.THREAD_WEIGHTS.MAX_BOOST
                                "
                                :step="0.1"
                                :min="0"
                                :max="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                    </el-collapse-item>

                    <!-- Relationship Weights -->
                    <el-collapse-item
                        title="Relationship Weights"
                        name="relationship_weights"
                    >
                        <el-form-item label="Direct">
                            <el-input-number
                                v-model="
                                    config.WEIGHTS.RELATIONSHIP_WEIGHTS.DIRECT
                                "
                                :step="0.1"
                                :min="0"
                                :max="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                        <el-form-item label="Parent">
                            <el-input-number
                                v-model="
                                    config.WEIGHTS.RELATIONSHIP_WEIGHTS.PARENT
                                "
                                :step="0.1"
                                :min="0"
                                :max="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                        <el-form-item label="Child">
                            <el-input-number
                                v-model="
                                    config.WEIGHTS.RELATIONSHIP_WEIGHTS.CHILD
                                "
                                :step="0.1"
                                :min="0"
                                :max="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                        <el-form-item label="Sibling">
                            <el-input-number
                                v-model="
                                    config.WEIGHTS.RELATIONSHIP_WEIGHTS.SIBLING
                                "
                                :step="0.1"
                                :min="0"
                                :max="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                        <el-form-item label="Cousin">
                            <el-input-number
                                v-model="
                                    config.WEIGHTS.RELATIONSHIP_WEIGHTS.COUSIN
                                "
                                :step="0.1"
                                :min="0"
                                :max="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                    </el-collapse-item>

                    <!-- Time Decay -->
                    <el-collapse-item title="Time Decay" name="time_decay">
                        <el-form-item label="Factor">
                            <el-input-number
                                v-model="config.WEIGHTS.TIME_DECAY.FACTOR"
                                :step="0.01"
                                :min="0"
                                :max="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                        <el-form-item label="Min Threshold">
                            <el-input-number
                                v-model="
                                    config.WEIGHTS.TIME_DECAY.MIN_THRESHOLD
                                "
                                :step="0.1"
                                :min="0"
                                :max="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                        <el-form-item label="Max Age (Weeks)">
                            <el-input-number
                                v-model="
                                    config.WEIGHTS.TIME_DECAY.MAX_AGE_WEEKS
                                "
                                :step="1"
                                :min="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                        <el-form-item label="Recent Days Threshold">
                            <el-input-number
                                v-model="
                                    config.WEIGHTS.TIME_DECAY
                                        .RECENT_DAYS_THRESHOLD
                                "
                                :step="1"
                                :min="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                    </el-collapse-item>

                    <!-- Component Weights -->
                    <el-collapse-item
                        title="Component Weights"
                        name="component_weights"
                    >
                        <el-form-item label="Relationship">
                            <el-input-number
                                v-model="
                                    config.WEIGHTS.COMPONENT_WEIGHTS
                                        .RELATIONSHIP
                                "
                                :step="0.05"
                                :min="0"
                                :max="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                        <el-form-item label="Type">
                            <el-input-number
                                v-model="config.WEIGHTS.COMPONENT_WEIGHTS.TYPE"
                                :step="0.05"
                                :min="0"
                                :max="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                        <el-form-item label="Interaction">
                            <el-input-number
                                v-model="
                                    config.WEIGHTS.COMPONENT_WEIGHTS.INTERACTION
                                "
                                :step="0.05"
                                :min="0"
                                :max="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                        <el-form-item label="Time Decay">
                            <el-input-number
                                v-model="
                                    config.WEIGHTS.COMPONENT_WEIGHTS.TIME_DECAY
                                "
                                :step="0.05"
                                :min="0"
                                :max="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                        <el-form-item label="Thread Length">
                            <el-input-number
                                v-model="
                                    config.WEIGHTS.COMPONENT_WEIGHTS
                                        .THREAD_LENGTH
                                "
                                :step="0.05"
                                :min="0"
                                :max="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                        <el-form-item label="Common Categories">
                            <el-input-number
                                v-model="
                                    config.WEIGHTS.COMPONENT_WEIGHTS
                                        .COMMON_CATEGORIES
                                "
                                :step="0.05"
                                :min="0"
                                :max="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                        <el-form-item label="Relationship Tweet Count">
                            <el-input-number
                                v-model="
                                    config.WEIGHTS.COMPONENT_WEIGHTS
                                        .RELATIONSHIP_TWEET_COUNT
                                "
                                :step="0.05"
                                :min="0"
                                :max="1"
                                :disabled="!weightsEnabled"
                            ></el-input-number>
                        </el-form-item>
                    </el-collapse-item>
                </el-collapse>

                <!-- Other Settings -->
                <el-form-item label="Minimum Score Threshold">
                    <el-input-number
                        v-model="config.WEIGHTS.MINIMUM_SCORE_THRESHOLD"
                        :step="0.1"
                        :min="0"
                        :max="1"
                        :disabled="!weightsEnabled"
                    ></el-input-number>
                </el-form-item>
                <el-form-item label="Enable Early Threshold Break">
                    <el-switch
                        v-model="config.WEIGHTS.ENABLE_EARLY_THRESHOLD_BREAK"
                        active-color="#13ce66"
                        inactive-color="#ff4949"
                    ></el-switch>
                </el-form-item>
                <el-form-item label="Hop Penalty">
                    <el-input-number
                        v-model="config.WEIGHTS.HOP_PENALTY"
                        :step="0.1"
                        :min="0"
                        :max="1"
                        :disabled="!weightsEnabled"
                    ></el-input-number>
                </el-form-item>

                <!-- Action Buttons -->
                <el-form-item>
                    <el-button type="primary" @click="saveConfig"
                        >Save Configuration</el-button
                    >
                    <el-button @click="resetConfig">Reset</el-button>
                </el-form-item>

                <!-- JSON Display -->
                <div class="json-section">
                    <div class="json-header">
                        <h3>Current Configuration</h3>
                        <el-button
                            size="small"
                            type="text"
                            @click="copyConfig"
                            class="copy-button"
                        >
                            <i class="el-icon-document-copy"></i> Copy JSON
                        </el-button>
                    </div>
                    <pre class="json-output">{{
                        JSON.stringify(config, null, 2)
                    }}</pre>
                </div>
            </el-form>
        </div>
    </el-drawer>
</template>

<script>
const defaultConfig = {
    WEIGHTS: {
        TYPE_WEIGHTS: {
            CUSTOM: 1,
            ACTIVE_SUBSCRIBED: 1,
            PASSIVE_SUBSCRIBED: 0.8,
            ACTIVE_UNSUBSCRIBED: 0.2,
            PASSIVE_UNSUBSCRIBED: 0.3,
        },
        INTERACTION_WEIGHTS: {
            BASE_MULTIPLIER: 0.1,
            MAX_BOOST: 0.5,
            RECENCY_FACTOR: 0.95,
        },
        THREAD_WEIGHTS: {
            BASE_LENGTH: 1,
            OPTIMAL_LENGTH: 1,
            MAX_BOOST: 0.3,
        },
        RELATIONSHIP_WEIGHTS: {
            DIRECT: 1,
            PARENT: 0.7,
            CHILD: 0.8,
            SIBLING: 0.5,
            COUSIN: 0.4,
        },
        TIME_DECAY: {
            FACTOR: 0.95,
            MIN_THRESHOLD: 0.1,
            MAX_AGE_WEEKS: 12,
            RECENT_DAYS_THRESHOLD: 2,
        },
        MINIMUM_SCORE_THRESHOLD: 0.4,
        ENABLE_EARLY_THRESHOLD_BREAK: false,
        COMPONENT_WEIGHTS: {
            RELATIONSHIP: 0.3,
            TYPE: 0.2,
            INTERACTION: 0.2,
            TIME_DECAY: 0.1,
            THREAD_LENGTH: 0.1,
            COMMON_CATEGORIES: 0.05,
            RELATIONSHIP_TWEET_COUNT: 0.05,
        },
        HOP_PENALTY: 0.1,
    },
    DAG: null,
    TWEET_URL: null,
    categoryMatchPrompt: null,
    llmProvider: null,
    USER_PREFERENCES: null,
};

export default {
    name: 'ConfigurationDrawer',
    data() {
        return {
            drawerVisible: false,
            config: JSON.parse(JSON.stringify(defaultConfig)),
            activeNames: ['json_output'],
            weightsEnabled: true,
        };
    },
    methods: {
        showDrawer() {
            this.drawerVisible = true;
        },
        hideDrawer() {
            this.drawerVisible = false;
        },
        saveConfig() {
            this.$emit('config-updated', this.config);
            this.hideDrawer();
        },
        resetConfig() {
            this.config = JSON.parse(JSON.stringify(defaultConfig));
        },
        copyConfig() {
            navigator.clipboard
                .writeText(JSON.stringify(this.config, null, 2))
                .then(() => {
                    this.$message({
                        message: 'Configuration copied to clipboard',
                        type: 'success',
                        duration: 2000,
                    });
                })
                .catch(() => {
                    this.$message({
                        message: 'Failed to copy configuration',
                        type: 'error',
                        duration: 2000,
                    });
                });
        },
        updateConfig(newConfig) {
            this.config = newConfig;
        },
    },
};
</script>

<style scoped>
.configuration-drawer {
    padding: 20px;
}
.el-form-item {
    margin-bottom: 20px;
}
.el-collapse-item {
    margin-bottom: 20px;
}
.json-section {
    margin-top: 20px;
    border-top: 1px solid #dcdfe6;
    padding-top: 20px;
}
.json-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 15px;
}
.json-header h3 {
    margin: 0;
}
.copy-button {
    padding: 0;
}
.copy-button i {
    margin-right: 4px;
}
.json-output {
    background-color: #f5f7fa;
    padding: 15px;
    border-radius: 4px;
    font-family: monospace;
    white-space: pre-wrap;
    word-wrap: break-word;
    font-size: 13px;
    max-height: 300px;
    overflow-y: auto;
}
:deep(.el-select) {
    width: 100%;
    max-width: 350px;
}

:deep(.el-form-item__content) {
    text-align: left;
}
</style>
