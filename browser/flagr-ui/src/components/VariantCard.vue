<template>
    <el-card shadow="hover">
        <el-form label-position="left" label-width="100px">
            <div class="flex-row id-row">
                <el-tag type="primary" :disable-transitions="true">
                    Variant ID: <b>{{ variant.id }}</b>
                </el-tag>
                <el-input
                    class="variant-key-input"
                    size="small"
                    placeholder="Key"
                    :value="variant.key" 
                    @input="updateVariantKey"
                >
                    <template slot="prepend">Key</template>
                </el-input>
                <div class="flex-row-right save-remove-variant-row">
                    <el-button slot="append" size="small" @click="saveVariant">
                        Save Variant
                    </el-button>
                    <el-button @click="requestDeleteVariant" size="small">
                        <span class="el-icon-delete" />
                    </el-button>
                    <el-button
                        slot="append"
                        size="small"
                        @click="applyConfig"
                        :type="variant.configStale ? 'warning' : 'primary'" 
                        plain
                    >
                        Apply Configuration
                    </el-button>
                    <el-button
                        slot="append"
                        size="small"
                        @click="evaluate"
                        type="success"
                        plain
                        :loading="isEvaluatingThisVariant" 
                        :disabled="variant.configStale || isEvaluatingThisVariant || isEvaluatingAnyOther || isSimulating"
                    >
                        Evaluate
                    </el-button>
                </div>
            </div>
            <el-collapse class="flex-row" v-model="activeCollapse">
                <el-collapse-item
                    title="Variant attachment"
                    name="attachment"
                    class="variant-attachment-collapsable-title"
                >
                    <p class="variant-attachment-title">
                        You can add JSON in key/value pairs format.
                    </p>
                    <vue-json-editor
                        :value="variant.attachment" 
                        @json-change="onJsonChange" 
                        @has-error="onJsonError" 
                        :showBtns="false"
                        :mode="'code'"
                        class="variant-attachment-content"
                    ></vue-json-editor>
                </el-collapse-item>
            </el-collapse>
        </el-form>

        <div v-if="variant.configStale" class="stale-config-warning">
            <i class="el-icon-warning"></i> Configuration has changed. Apply the latest to this variant before evaluating.
        </div>

        <div v-if="variant.evaluationResult" class="evaluation-result">
            <div class="evaluation-header">
                <h4>Evaluation Result</h4>
            </div>
            
            <!-- Parse and display category response if available -->
            <div v-if="parsedCategoryResponse && parsedCategoryResponse.hasCategories" class="category-response-section">
                <h5>Tweet Categories{{ categoryModelName ? ` from ${categoryModelName}` : '' }}</h5>
                <div class="tweet-categories">
                    <div
                        v-for="(categories, level) in parsedCategoryResponse.displayableCategories"
                        :key="level"
                        class="category-level"
                    >
                        <strong>{{ level }}:</strong>
                        <span v-if="categories.length > 0">
                            <el-tag 
                                v-for="category in categories" 
                                :key="category.id || category.name"
                                size="small"
                                :type="getCategoryTagType(level)"
                                effect="plain"
                                class="category-tag"
                            >
                                {{ category.name }}
                            </el-tag>
                        </span>
                        <span v-else class="no-categories-inline">(none)</span>
                    </div>
                </div>
            </div>
            
            <!-- Show other evaluation result data -->
            <el-collapse v-if="variant.evaluationResult.scores" v-model="activeScoresCollapse" class="evaluation-sub-section-collapse">
                <el-collapse-item name="scores" class="scores-collapse-item">
                    <template slot="title">
                        <h5 class="sub-section-title">Matching Scores</h5>
                    </template>
                    <div class="scores-content">
                        <div><strong>Final Score:</strong> {{ variant.evaluationResult.scores.stats.finalScore.toFixed(4) }}</div>
                        <div><strong>Avg Type Multiplier:</strong> {{ variant.evaluationResult.scores.stats.avgTypeMultiplier.toFixed(4) }}</div>
                        <div><strong>Avg Interaction Boost:</strong> {{ variant.evaluationResult.scores.stats.avgInteractionBoost.toFixed(4) }}</div>
                        <div><strong>Avg Time Decay:</strong> {{ variant.evaluationResult.scores.stats.avgTimeDecay.toFixed(4) }}</div>

                        <div v-if="variant.evaluationResult.scores.matches && variant.evaluationResult.scores.matches.length > 0" class="matches-list">
                            <h6>Category Matches ({{ variant.evaluationResult.scores.matches.length }}):</h6>
                            <el-collapse accordion class="match-details-collapse">
                                <el-collapse-item 
                                    v-for="(match, index) in variant.evaluationResult.scores.matches" 
                                    :key="index"
                                    :name="index"
                                    class="match-item"
                                >
                                    <template slot="title">
                                        <div class="match-title">
                                            <span class="match-tier-indicator" :class="getTierClass(match.tier)"></span>
                                            <span class="match-category-ids">
                                                <strong>User:</strong> {{ extractCategoryName(match.userCategoryId) }} 
                                                <i class="el-icon-right"></i> 
                                                <strong>Tweet:</strong> {{ extractCategoryName(match.tweetCategoryId) }}
                                            </span>
                                            <el-tag size="mini" :type="getTierTagType(match.tier)" effect="dark" class="match-tier-tag">{{ match.tier }}</el-tag>
                                            <span class="match-score">Score: {{ match.score.toFixed(4) }}</span>
                                        </div>
                                    </template>
                                    <div class="match-details">
                                        <div class="match-detail-grid">
                                            <div><strong>Relationship:</strong> {{ match.relationship }}</div>
                                            <div><strong>Hop Length:</strong> {{ match.hopLength }}</div>
                                            <div><strong>Relation Score:</strong> {{ match.relationScore.toFixed(4) }}</div>
                                            <div><strong>Type Multiplier:</strong> {{ match.typeMultiplier.toFixed(4) }}</div>
                                            <div><strong>Interaction Boost:</strong> {{ match.interactionBoost.toFixed(4) }}</div>
                                            <div><strong>Time Decay:</strong> {{ match.timeDecayFactor.toFixed(4) }}</div>
                                            <div v-if="match.authorTweetCount">
                                                <strong>Author Tweet Counts:</strong> 
                                                User Cat: {{ match.authorTweetCount.userCategory }}, 
                                                Tweet Cat: {{ match.authorTweetCount.chainCategory }}
                                            </div>
                                            <div><strong>Common Categories Boost:</strong> {{ match.commonCategoriesBoost.toFixed(4) }}</div>
                                            <div><strong>Relationship Tweet Count:</strong> {{ match.relationshipTweetCount }}</div>
                                        </div>
                                    </div>
                                </el-collapse-item>
                            </el-collapse>
                        </div>
                        <div v-else>
                            <p>No category matches found.</p>
                        </div>
                    </div>
                </el-collapse-item>
            </el-collapse>
            
            <div v-if="variant.evaluationResult.evaluationResult" class="evaluation-details-section">
                <h5>Evaluation Details</h5>
                <div class="evaluation-details-content">
                    <div><strong>Final Score:</strong> {{ variant.evaluationResult.evaluationResult.finalScore }}</div>
                    <div><strong>Should Send:</strong> {{ variant.evaluationResult.evaluationResult.shouldSend ? 'Yes' : 'No' }}</div>
                    <div><strong>Performed Category Match:</strong> {{ variant.evaluationResult.evaluationResult.performedCategoryMatch ? 'Yes' : 'No' }}</div>
                </div>
            </div>
            
            <!-- Collapsible raw JSON for full details -->
            <div class="raw-result-section">
                <el-collapse>
                    <el-collapse-item title="Raw Evaluation Result">
                        <pre class="evaluation-json">{{ JSON.stringify(variant.evaluationResult, null, 2) }}</pre>
                    </el-collapse-item>
                </el-collapse>
            </div>
        </div>
    </el-card>
</template>

<script>
import vueJsonEditor from 'vue-json-editor';

export default {
    name: 'VariantCard',
    components: {
        vueJsonEditor,
    },
    props: {
        variant: {
            type: Object,
            required: true,
        },
        // flagId: { // Not strictly needed if all actions emit to parent
        //     type: Number,
        //     required: true,
        // },
        isEvaluatingAnyOther: { // True if any *other* variant is evaluating
            type: Boolean,
            default: false,
        },
        isSimulating: { // True if A/B test simulation is running
            type: Boolean,
            default: false,
        }
    },
    data() {
        return {
            internalAttachmentValid: true,
            activeCollapse: [], // To control the collapse state, can be preset e.g. ['attachment']
            activeScoresCollapse: ['scores'], // Controls the collapse state for the scores section
            // Local loading state for this specific variant's evaluation
            isEvaluatingThisVariant: false, 
        };
    },
    computed: {
        // Use variant.evaluating directly if parent manages it and passes it down.
        // Or manage it locally if preferred, as done with isEvaluatingThisVariant.
        parsedCategoryResponse() {
            if (!this.variant.evaluationResult || 
                !this.variant.evaluationResult.categorizationMetrics || 
                !this.variant.evaluationResult.categorizationMetrics.categoryResponse) {
                return { hasCategories: false, displayableCategories: {} };
            }

            const categoryResponse = this.variant.evaluationResult.categorizationMetrics.categoryResponse;
            const displayableCategories = {};

            // Parse each level (root, branch, leaf)
            ['root', 'branch', 'leaf'].forEach(level => {
                if (categoryResponse[level] && Array.isArray(categoryResponse[level])) {
                    displayableCategories[level] = categoryResponse[level];
                } else if (level === 'root') {
                    // Always show root level even if empty
                    displayableCategories[level] = [];
                }
            });

            // Check if there are any categories
            const hasCategories = Object.values(displayableCategories).some(categories => 
                Array.isArray(categories) && categories.length > 0
            );

            return {
                hasCategories,
                displayableCategories
            };
        },
        categoryModelName() {
            return this.variant.evaluationResult?.categorizationMetrics?.modelName;
        }
    },
    methods: {
        updateVariantKey(newKey) {
            // Emit an event for the parent to update the variant object
            // This approach is preferred for complex objects to maintain single source of truth in parent
            this.$emit('update:variant', { ...this.variant, key: newKey });
        },
        onJsonChange(newJson) {
            this.internalAttachmentValid = true; // Assuming change means it could be valid
            this.$emit('update:variant', { ...this.variant, attachment: newJson, attachmentValid: true });
        },
        onJsonError(error) {
            console.error('JSON validation error in variant card:', error);
            this.internalAttachmentValid = false;
            this.$emit('update:variant', { ...this.variant, attachmentValid: false });
            // Optionally emit an error event for parent to display message
            this.$emit('attachment-error', this.variant.id);
        },
        saveVariant() {
            if (!this.internalAttachmentValid) {
                // Parent should ideally show the message, but can emit an event for it
                this.$emit('show-message', {type: 'error', message: 'Variant attachment is not valid'});
                return;
            }
            // Emit variant data for parent to handle the PUT request
            this.$emit('save', this.variant);
        },
        requestDeleteVariant() {
            this.$emit('delete', this.variant);
        },
        applyConfig() {
            this.$emit('apply-config', this.variant);
        },
        async evaluate() {
            if (!this.variant.attachment) {
                this.$emit('show-message', {type: 'error', message: 'No configuration applied to evaluate'});
                return;
            }
            this.isEvaluatingThisVariant = true;
            try {
                // Parent will handle the actual API call
                await this.$emit('evaluate', this.variant);
            } catch(e) {
                 // Parent will show error, this is just to ensure loading state is reset
            } finally {
                // Parent should control the global isAnyVariantEvaluating and variant.evaluating flags.
                // This local flag is mostly for the button's immediate loading state.
                // Consider if this needs to be reset here or if it's purely driven by a prop.
                // For now, we assume parent sets variant.evaluating to false which will flow down.
                // If not, uncomment: this.isEvaluatingThisVariant = false;
            }
        },
        getCategoryTagType(level) {
            // Return different tag types for different category levels
            switch(level) {
                case 'root':
                    return 'primary';
                case 'branch':
                    return 'success';
                case 'leaf':
                    return 'warning';
                default:
                    return 'info';
            }
        },
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
            // Assumes format like "category-level-name-with-hyphens"
            const parts = categoryId.split('-');
            if (parts.length > 2) {
                return parts.slice(2).join(' ').replace(/\b\w/g, l => l.toUpperCase()); // Capitalize each word
            }
            return categoryId; // Fallback to full ID if format is unexpected
        }
    },
    watch: {
        // If parent updates variant.evaluating, reflect it on isEvaluatingThisVariant
        // This creates a two-way binding feel for the loading state specific to this card.
        'variant.evaluating': function(newVal) {
            this.isEvaluatingThisVariant = newVal;
        }
    }
};
</script>

<style scoped lang="less">
/* Styles copied from Flag.vue, prefixed or ensure no conflicts */
.el-card {
    margin-bottom: 1em;
}
.flex-row {
    display: flex;
    align-items: center;
}
.id-row {
    margin-bottom: 8px;
    flex-wrap: wrap; /* Allow wrapping for smaller screens */
}
.el-input-group__prepend {
    width: auto; /* Let it size based on content like "Key" */
}
.variant-key-input {
    margin-left: 10px;
    width: auto; /* Adjust as needed, maybe flex-grow */
    flex-grow: 1;
    min-width: 150px; /* Minimum width */
    margin-right: 10px;
}
.save-remove-variant-row {
    padding-bottom: 5px; /* From original */
    margin-left: auto; /* Pushes buttons to the right */
    display: flex;
    gap: 5px; /* Space between buttons */
    flex-wrap: nowrap; /* Keep buttons on one line if possible */
}

.variant-attachment-collapsable-title {
    /* margin: 0; */ /* Original commented out, consider if needed */
    font-size: 13px;
    color: #909399;
    width: 100%;
}

.variant-attachment-title {
    margin: 0 0 5px 0; /* Add some bottom margin */
    font-size: 13px;
    color: #909399;
}

.variant-attachment-content {
    /* Style for vue-json-editor container if needed */
}

.evaluation-result {
    margin-top: 15px;
    padding-top: 15px;
    border-top: 1px solid #dcdfe6;
}

.evaluation-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 10px;
}

.evaluation-header h4 {
    margin: 0;
    color: #606266;
}

.evaluation-json {
    background-color: #f5f7fa;
    padding: 10px;
    border-radius: 4px;
    font-family: monospace;
    font-size: 12px;
    white-space: pre-wrap;
    word-wrap: break-word;
    max-height: 200px;
    overflow-y: auto;
}

.stale-config-warning {
    color: #E6A23C; /* Element UI warning color */
    margin-top: 10px;
    margin-bottom: 5px;
    font-size: 0.9em;
    display: flex;
    align-items: center;
}

.stale-config-warning i {
    margin-right: 5px;
    font-size: 1.1em;
}

.category-response-section,
.scores-section,
.evaluation-details-section,
.raw-result-section {
    margin-bottom: 15px;
}

.category-response-section h5,
.scores-section h5,
.evaluation-details-section h5 {
    margin: 10px 0 5px 0;
    font-size: 14px;
    color: #606266;
    padding: 0;
}

.tweet-categories,
.scores-content,
.evaluation-details-content {
    background-color: #f5f7fa;
    border-radius: 4px;
    padding: 10px;
}

.category-level {
    margin-bottom: 8px;
    word-break: break-word;
}

.category-tag {
    margin-right: 5px;
    margin-bottom: 5px;
}

.no-categories-inline {
    color: #909399;
    font-style: italic;
}

.scores-content div,
.evaluation-details-content div {
    margin-bottom: 5px;
}

.matches-list {
    margin-top: 15px; /* Increased top margin */
    padding-top: 10px; /* Add some padding above the list */
    border-top: 1px solid #ebeef5; /* Separator line */
}

.matches-list h6 {
    margin-bottom: 10px;
    font-size: 13px; /* Slightly smaller than h5 */
    color: #303133; /* Darker text for the sub-header */
    font-weight: bold;
}

.match-details-collapse .el-collapse-item__header {
    font-size: 13px; /* Consistent font size */
    border-bottom: 1px solid #f0f2f5; /* Lighter border for collapse items */
}

.match-details-collapse .el-collapse-item__wrap {
    border-bottom: none; /* Remove default bottom border from content wrap */
}

.match-item {
    /* Styles for individual match item if needed, but el-collapse-item provides structure */
    background-color: #fff; /* Ensure background for items */
    border-radius: 3px; /* Slightly rounded corners */
    margin-bottom: 8px; /* Space between match items */
}

.match-title {
    display: flex;
    align-items: center;
    width: 100%; /* Ensure title takes full width */
    padding: 5px 0; /* Add some padding to title */
}

.match-tier-indicator {
    min-width: 10px; /* Ensure width */
    height: 10px;
    border-radius: 50%;
    margin-right: 10px; /* Space after indicator */
    flex-shrink: 0; /* Prevent shrinking */
}

/* Tier specific colors - good to define these based on your theme */
.tier-excellent {
    background-color: #67c23a; /* Element UI Success Green */
}
.tier-good {
    background-color: #409eff; /* Element UI Primary Blue */
}
.tier-fair {
    background-color: #e6a23c; /* Element UI Warning Orange */
}
.tier-poor {
    background-color: #f56c6c; /* Element UI Danger Red */
}
.tier-unknown {
    background-color: #909399; /* Element UI Info Gray */
}

.match-category-ids {
    flex-grow: 1;
    font-size: 13px;
    color: #555;
    overflow: hidden; /* Prevent overflow */
    text-overflow: ellipsis; /* Add ellipsis for long names */
    white-space: nowrap; /* Keep on one line */
    margin-right: 10px;
}

.match-category-ids strong {
    color: #303133;
}

.match-category-ids .el-icon-right {
    margin: 0 5px;
    color: #c0c4cc;
}

.match-tier-tag {
    margin-left: auto; /* Push tag to the right of category IDs */
    margin-right: 10px;
    flex-shrink: 0;
}

.match-score {
    font-size: 13px;
    font-weight: bold;
    color: #303133;
    min-width: 100px; /* Give score some space */
    text-align: right;
    flex-shrink: 0;
}

.match-details {
    padding: 10px 15px; /* Padding inside the collapsible content */
    background-color: #fbfdff; /* Slightly different background for details */
    font-size: 12px;
    color: #606266;
}

.match-detail-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); /* Responsive grid */
    gap: 8px; /* Gap between grid items */
}

.match-detail-grid div {
    padding: 4px 0; /* Padding for each detail item */
}

.match-detail-grid strong {
    color: #303133;
}

.evaluation-sub-section-collapse .el-collapse-item__header {
    /*border-bottom: none; !* Remove default bottom border if it looks too heavy *!*/
    /*padding: 0 5px; !* Adjust padding if needed *!*/
}

.evaluation-sub-section-collapse .sub-section-title {
    margin: 0; /* Remove default margins from h5 */
    font-size: 14px; /* Match other section titles */
    color: #606266; /* Match other section titles */
    font-weight: 600; /* Slightly bolder for section titles */
}

.scores-collapse-item .el-collapse-item__content {
    padding-bottom: 0; /* Remove default bottom padding from content if needed */
}
</style> 