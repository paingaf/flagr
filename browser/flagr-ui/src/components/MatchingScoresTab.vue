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
                    class="simulation-result ab-test-result-display"
                >
                    <div class="simulation-header">
                        <h4>A/B Test Simulation Result</h4>
                    </div>

                    <div v-if="abTestResult.comparison" class="comparison-metrics">
                        <h5>Comparison Summary</h5>
                        <el-table
                            :data="comparisonTableMetrics"
                            style="width: 100%"
                            border
                            class="comparison-table"
                        >
                            <el-table-column prop="metricName" label="Metric" width="150"></el-table-column>
                            
                            <el-table-column 
                                v-for="key in abTestVariantKeys" 
                                :key="key" 
                                :label="`Variant ${key}`"
                                align="center"
                            >
                                <template slot-scope="scope">
                                    <span v-if="scope.row.metricName === 'Overall Score' && scope.row[key] !== null">{{ scope.row[key].toFixed(4) }}</span>
                                    <span v-else-if="scope.row.metricName === 'Cost ($)' && scope.row[key] !== null">{{ scope.row[key].toFixed(6) }}</span>
                                    <span v-else>{{ scope.row[key] }}</span>
                                </template>
                            </el-table-column>

                            <el-table-column 
                                v-for="key in abTestVariantKeys.filter(k => k !== 'A')" 
                                :key="`diff_${key}_A`" 
                                :label="`Diff (Var ${key} - Var A)`"
                                align="center"
                            >
                                <template slot-scope="scope">
                                    <div v-if="scope.row.metricName === 'Overall Score' && scope.row[`diff_${key}_A`] !== undefined" :class="getDifferenceClass(scope.row[`diff_${key}_A`])">
                                        {{ scope.row[`diff_${key}_A`].toFixed(4) }}
                                        <i :class="getDifferenceIcon(scope.row[`diff_${key}_A`])"></i>
                                    </div>
                                    <div v-else-if="scope.row.metricName === 'Cost ($)' && scope.row[`diff_${key}_A`] !== undefined" :class="getDifferenceClass(scope.row[`diff_${key}_A`], true)">
                                        {{ scope.row[`diff_${key}_A`].toFixed(6) }}
                                        <i :class="getDifferenceIcon(scope.row[`diff_${key}_A`], true)"></i>
                                    </div>
                                    <span v-else-if="scope.row.metricName === 'Latency'">-</span>
                                    <span v-else>N/A</span>
                                </template>
                            </el-table-column>
                        </el-table>
                    </div>

                    <!-- Detailed Matches per Variant -->
                    <div v-if="abTestVariantDetails.length > 0" class="detailed-variant-matches">
                        <h5>Detailed Variant Matches</h5>
                        <el-tabs type="border-card">
                            <el-tab-pane 
                                v-for="variantResult in abTestVariantDetails" 
                                :key="variantResult.keyName" 
                                :label="variantResult.name"
                            >
                                <div v-if="variantResult.scores && variantResult.scores.matches && variantResult.scores.matches.length > 0" class="matches-list-ab">
                                    <el-collapse accordion class="match-details-collapse-ab">
                                        <el-collapse-item 
                                            v-for="(match, index) in variantResult.scores.matches" 
                                            :key="`${variantResult.keyName}-match-${index}`"
                                            :name="`${variantResult.keyName}-match-${index}`"
                                            class="match-item-ab"
                                        >
                                            <template slot="title">
                                                <div class="match-title-ab">
                                                    <span class="match-tier-indicator-ab" :class="getTierClass(match.tier)"></span>
                                                    <span class="match-category-ids-ab">
                                                        <strong>User:</strong> {{ extractCategoryName(match.userCategoryId) }} 
                                                        <i class="el-icon-right"></i> 
                                                        <strong>Tweet:</strong> {{ extractCategoryName(match.tweetCategoryId) }}
                                                    </span>
                                                    <el-tag size="mini" :type="getTierTagType(match.tier)" effect="dark" class="match-tier-tag-ab">{{ match.tier }}</el-tag>
                                                    <span class="match-score-ab">Score: {{ match.score ? match.score.toFixed(4) : 'N/A' }}</span>
                                                </div>
                                            </template>
                                            <div class="match-details-ab">
                                                <div class="match-detail-grid-ab">
                                                    <div><strong>Relationship:</strong> {{ match.relationship }}</div>
                                                    <div><strong>Hop Length:</strong> {{ match.hopLength }}</div>
                                                    <div><strong>Relation Score:</strong> {{ match.relationScore ? match.relationScore.toFixed(4) : 'N/A' }}</div>
                                                    <div><strong>Type Multiplier:</strong> {{ match.typeMultiplier ? match.typeMultiplier.toFixed(4) : 'N/A' }}</div>
                                                    <div><strong>Interaction Boost:</strong> {{ match.interactionBoost ? match.interactionBoost.toFixed(4) : 'N/A' }}</div>
                                                    <div><strong>Time Decay:</strong> {{ match.timeDecayFactor ? match.timeDecayFactor.toFixed(4) : 'N/A' }}</div>
                                                    <div v-if="match.authorTweetCount">
                                                        <strong>Author Tweet Counts:</strong> 
                                                        User Cat: {{ match.authorTweetCount.userCategory }}, 
                                                        Tweet Cat: {{ match.authorTweetCount.chainCategory }}
                                                    </div>
                                                    <div><strong>Common Categories Boost:</strong> {{ match.commonCategoriesBoost ? match.commonCategoriesBoost.toFixed(4) : 'N/A' }}</div>
                                                    <div><strong>Relationship Tweet Count:</strong> {{ match.relationshipTweetCount }}</div>
                                                </div>
                                            </div>
                                        </el-collapse-item>
                                    </el-collapse>
                                </div>
                                <div v-else>
                                    <p>No category matches found for {{ variantResult.name }}.</p>
                                </div>
                            </el-tab-pane>
                        </el-tabs>
                    </div>
                    
                    <!-- Collapsible Raw JSON -->
                    <el-collapse class="raw-json-collapse">
                        <el-collapse-item title="Raw A/B Test Result JSON" name="rawABResult">
                            <pre class="simulation-json">{{ JSON.stringify(abTestResult, null, 2) }}</pre>
                        </el-collapse-item>
                    </el-collapse>
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
    computed: {
        scoreDifference() {
            if (this.abTestResult && this.abTestResult.comparison && this.abTestResult.comparison.scoreMetrics) {
                const { scoreA, scoreB } = this.abTestResult.comparison.scoreMetrics;
                if (typeof scoreA === 'number' && typeof scoreB === 'number') {
                    return scoreB - scoreA;
                }
            }
            return null;
        },
        costDifference() {
            if (this.abTestResult && this.abTestResult.comparison && this.abTestResult.comparison.costMetrics) {
                const { costA, costB, difference } = this.abTestResult.comparison.costMetrics;
                if (typeof difference === 'number') return difference;
                if (typeof costA === 'number' && typeof costB === 'number') {
                    return costB - costA;
                }
            }
            return null;
        },
        abTestVariantDetails() {
            if (!this.abTestResult) return [];
            const variantDetails = [];
            const variantResultKeys = Object.keys(this.abTestResult).filter(key => 
                key.endsWith('TestResults') && key.length === 'ATestResults'.length
            );
            variantResultKeys.sort();
            for (const key of variantResultKeys) {
                const variantLetter = key.charAt(0);
                variantDetails.push({
                    name: `Variant ${variantLetter}`,
                    keyName: variantLetter,
                    ...this.abTestResult[key]
                });
            }
            return variantDetails;
        },
        abTestVariantKeys() {
            return this.abTestVariantDetails.map(v => v.keyName).sort();
        },
        comparisonTableMetrics() {
            if (!this.abTestResult || !this.abTestVariantKeys.length) return [];

            const variants = this.abTestVariantKeys;
            const metrics = [];
            const comparisonData = this.abTestResult.comparison || {};

            // --- Score Metric --- 
            const scoreRow = { metricName: 'Overall Score' };
            let scoreA_value = null;
            variants.forEach(vKey => {
                const resultKey = `${vKey}TestResults`;
                const score = this.abTestResult[resultKey]?.scores?.stats?.finalScore;
                scoreRow[vKey] = typeof score === 'number' ? score : null;
                if (vKey === 'A') scoreA_value = scoreRow[vKey];
            });
            variants.forEach(vKey => {
                if (vKey !== 'A' && scoreA_value !== null && scoreRow[vKey] !== null) {
                    scoreRow[`diff_${vKey}_A`] = scoreRow[vKey] - scoreA_value;
                }
            });
            metrics.push(scoreRow);

            // --- Latency Metric --- 
            const latencyRow = { metricName: 'Latency' };
            const perfMetrics = comparisonData.performanceMetrics || {};
            variants.forEach(vKey => {
                latencyRow[vKey] = perfMetrics[`latency${vKey}`] || 'N/A';
            });
            metrics.push(latencyRow);

            // --- Cost Metric --- 
            const costRow = { metricName: 'Cost ($)' };
            const costMetricsData = comparisonData.costMetrics || {};
            let costA_value = null;
            variants.forEach(vKey => {
                const costVal = costMetricsData[`cost${vKey}`];
                costRow[vKey] = typeof costVal === 'number' ? costVal : null;
                if (vKey === 'A') costA_value = costRow[vKey];
            });
            if (typeof costMetricsData.difference === 'number' && variants.includes('B') && costA_value !== null && costRow['B'] !== null) {
                costRow[`diff_B_A`] = costMetricsData.difference;
            }
            variants.forEach(vKey => {
                if (vKey !== 'A' && typeof costRow[`diff_${vKey}_A`] === 'undefined' && costA_value !== null && costRow[vKey] !== null) {
                    costRow[`diff_${vKey}_A`] = costRow[vKey] - costA_value;
                }
            });
            metrics.push(costRow);
            
            return metrics;
        }
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
        getDifferenceClass(difference, lowerIsBetter = false) {
            if (difference === null || difference === 0) return 'neutral-difference';
            if (lowerIsBetter) {
                return difference < 0 ? 'positive-difference' : 'negative-difference';
            }
            return difference > 0 ? 'positive-difference' : 'negative-difference';
        },
        getDifferenceIcon(difference, lowerIsBetter = false) {
            if (difference === null || difference === 0) return ''; // No icon for no difference
            let iconClass = '';
            if (lowerIsBetter) {
                iconClass = difference < 0 ? 'el-icon-top' : 'el-icon-bottom';
            } else {
                iconClass = difference > 0 ? 'el-icon-top' : 'el-icon-bottom';
            }
            const trendClass = this.getDifferenceClass(difference, lowerIsBetter);
            return `${iconClass} ${trendClass}`;
        },
        // Copied from VariantCard.vue for displaying detailed matches
        getTierClass(tier) {
            if (!tier) return 'tier-unknown';
            return `tier-${tier.toLowerCase().replace('_', '-')}`;
        },
        getTierTagType(tier) {
            if (!tier) return 'info';
            switch (tier.toUpperCase()) {
                case 'EXCELLENT':
                    return 'success';
                case 'GOOD':
                    return 'primary';
                case 'FAIR':
                    return 'warning';
                case 'POOR':
                    return 'danger';
                default:
                    return 'info';
            }
        },
        extractCategoryName(categoryId) {
            if (!categoryId) return 'N/A';
            const parts = categoryId.split('-');
            if (parts.length > 2) {
                return parts.slice(2).join(' ').replace(/\b\w/g, l => l.toUpperCase());
            }
            return categoryId;
        }
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

/* A/B Test Result Display Styles */
.ab-test-result-display h5 {
    margin-top: 15px;
    margin-bottom: 10px;
    font-size: 1.1em;
    color: #303133;
}

.comparison-row {
    margin-bottom: 15px;
}

.metric-card .el-card__header {
    padding: 10px 15px;
    background-color: #fafafa;
    font-weight: bold;
    font-size: 0.95em;
    color: #555;
}

.metric-card .el-card__body {
    padding: 15px;
    font-size: 0.9em;
    line-height: 1.6;
}

.metric-card .el-card__body div {
    margin-bottom: 5px;
}

.positive-difference {
    color: #67c23a; /* Element UI Success Green */
    font-weight: bold;
}

.negative-difference {
    color: #f56c6c; /* Element UI Danger Red */
    font-weight: bold;
}

.neutral-difference {
    color: #909399; /* Element UI Info Gray */
}

.positive-difference .el-icon-top,
.negative-difference .el-icon-bottom {
    font-weight: bold; /* Icons inherit color, make them bold too */
}

.raw-json-collapse {
    margin-top: 15px;
}

.raw-json-collapse .el-collapse-item__header {
    font-size: 0.9em; /* Smaller header for raw JSON */
    color: #606266;
}

/* Comparison Table Styles */
.comparison-table {
    margin-bottom: 20px; /* Space below the table */
}

.comparison-table .el-table__header th {
    background-color: #fafafa; /* Light background for header */
    color: #303133; /* Darker text for header */
    font-weight: bold;
}

.comparison-table .el-table__row td {
    font-size: 0.9em;
}

/* Styles for Detailed Variant Matches in A/B Test */
.detailed-variant-matches h5 {
    margin-top: 20px;
    margin-bottom: 10px;
    font-size: 1.1em;
    color: #303133;
}

.matches-list-ab {
    margin-top: 10px;
}

.match-details-collapse-ab .el-collapse-item__header {
    font-size: 13px;
    border-bottom: 1px solid #f0f2f5;
}

.match-details-collapse-ab .el-collapse-item__wrap {
    border-bottom: none;
}

.match-item-ab {
    background-color: #fff;
    border-radius: 3px;
    margin-bottom: 8px;
}

.match-title-ab {
    display: flex;
    align-items: center;
    width: 100%;
    padding: 5px 0;
}

.match-tier-indicator-ab {
    min-width: 10px;
    height: 10px;
    border-radius: 50%;
    margin-right: 10px;
    flex-shrink: 0;
}

/* Tier specific colors are reused from VariantCard or can be defined here if not global */
/* .tier-excellent, .tier-good, etc. */

.match-category-ids-ab {
    flex-grow: 1;
    font-size: 13px;
    color: #555;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    margin-right: 10px;
}

.match-category-ids-ab strong {
    color: #303133;
}

.match-category-ids-ab .el-icon-right {
    margin: 0 5px;
    color: #c0c4cc;
}

.match-tier-tag-ab {
    margin-left: auto;
    margin-right: 10px;
    flex-shrink: 0;
}

.match-score-ab {
    font-size: 13px;
    font-weight: bold;
    color: #303133;
    min-width: 100px;
    text-align: right;
    flex-shrink: 0;
}

.match-details-ab {
    padding: 10px 15px;
    background-color: #fbfdff;
    font-size: 12px;
    color: #606266;
}

.match-detail-grid-ab {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 8px;
}

.match-detail-grid-ab div {
    padding: 4px 0;
}

.match-detail-grid-ab strong {
    color: #303133;
}

.el-tabs--border-card > .el-tabs__content {
    padding: 10px; /* Reduce padding for nested tabs content */
}
</style> 