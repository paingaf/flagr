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
                        type="primary"
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
                        :disabled="isEvaluatingThisVariant || isEvaluatingAnyOther || isSimulating"
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

        <div v-if="variant.evaluationResult" class="evaluation-result">
            <div class="evaluation-header">
                <h4>Evaluation Result</h4>
            </div>
            <pre class="evaluation-json">{{ JSON.stringify(variant.evaluationResult, null, 2) }}</pre>
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
            // Local loading state for this specific variant's evaluation
            isEvaluatingThisVariant: false, 
        };
    },
    computed: {
        // Use variant.evaluating directly if parent manages it and passes it down.
        // Or manage it locally if preferred, as done with isEvaluatingThisVariant.
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
                await this.$emit('evaluate', this.variant, (success) => {
                    // Optional: callback to reset loading state based on parent's success/failure
                    // this.isEvaluatingThisVariant = false; 
                    // Parent should set variant.evaluating which this component can watch or receive as prop
                });
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
</style> 