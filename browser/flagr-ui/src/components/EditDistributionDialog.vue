<template>
    <el-dialog
        title="Edit distribution"
        :visible.sync="isVisible"
        @close="closeDialog"
        width="50%" 
        top="5vh"
    >
        <div v-if="currentSegment && localVariants.length">
            <div
                v-for="variant in localVariants"
                :key="'distribution-variant-' + variant.id"
                class="distribution-variant-row"
            >
                <div class="variant-info">
                    <el-checkbox
                        @change="(checked) => selectVariant(checked, variant)"
                        :checked="!!localDistributions[variant.id]"
                    ></el-checkbox>
                    <el-tag
                        type="danger"
                        :disable-transitions="true"
                        >{{ variant.key }}</el-tag
                    >
                </div>
                <div class="slider-container">
                    <el-slider
                        v-if="!localDistributions[variant.id]"
                        :value="0"
                        :disabled="true"
                        show-input
                        class="distribution-slider"
                    ></el-slider>
                    <div v-if="!!localDistributions[variant.id]">
                        <el-slider
                            v-model="localDistributions[variant.id].percent"
                            :disabled="false"
                            show-input
                            class="distribution-slider"
                        ></el-slider>
                    </div>
                </div>
            </div>
        </div>
        <div v-else>
            <p>No segment data or variants to display.</p>
        </div>

        <el-button
            class="width--full save-button"
            :disabled="!newDistributionIsValid"
            @click.prevent="save"
            >Save</el-button
        >

        <el-alert
            class="edit-distribution-alert"
            v-if="!newDistributionIsValid"
            :title="
                'Percentages must add up to 100% (currently at ' +
                newDistributionPercentageSum +
                '%)'
            "
            type="error"
            show-icon
        ></el-alert>
    </el-dialog>
</template>

<script>
import clone from 'lodash.clone'; // Ensure lodash.clone is available or use structuredClone
import { sum, pluck } from '@/helpers/helpers'; // Import the sum and pluck functions

const DEFAULT_DISTRIBUTION = {
    bitmap: '', // You may need to adjust this default or ensure it's handled
    variantID: 0,
    variantKey: '',
    percent: 0,
};

export default {
    name: 'EditDistributionDialog',
    props: {
        visible: {
            type: Boolean,
            default: false,
        },
        segment: { // The segment whose distributions are being edited
            type: Object,
            default: null,
        },
        variants: { // All available variants for the flag
            type: Array,
            default: () => [],
        },
    },
    data() {
        return {
            localDistributions: {},
            currentSegment: null, // Local copy of the segment prop
            localVariants: [] // Local copy of variants prop
        };
    },
    computed: {
        isVisible: {
            get() {
                return this.visible;
            },
            set(value) {
                if (!value) {
                    this.closeDialog();
                }
            },
        },
        newDistributionPercentageSum() {
            if (Object.keys(this.localDistributions).length === 0) return 0;
            return sum(pluck(Object.values(this.localDistributions), 'percent'));
        },
        newDistributionIsValid() {
            return this.newDistributionPercentageSum === 100;
        },
    },
    watch: {
        visible(newVal) {
            if (newVal && this.segment) {
                this.currentSegment = clone(this.segment);
                this.localVariants = clone(this.variants);
                this.initializeLocalDistributions();
            } else {
                // Reset when dialog is hidden
                this.localDistributions = {};
                this.currentSegment = null;
                this.localVariants = [];
            }
        },
        // Watch segment prop for external changes if dialog is already visible
        segment(newSegment) {
            if (this.visible && newSegment) {
                this.currentSegment = clone(newSegment);
                this.initializeLocalDistributions();
            }
        },
        variants(newVariants) {
            if (this.visible) {
                this.localVariants = clone(newVariants);
                // Re-initialize if variants change, to ensure consistency
                this.initializeLocalDistributions(); 
            }
        }
    },
    methods: {
        initializeLocalDistributions() {
            const newDist = {};
            if (this.currentSegment && this.currentSegment.distributions) {
                this.currentSegment.distributions.forEach((distribution) => {
                    // Ensure variant still exists
                    if (this.localVariants.find(v => v.id === distribution.variantID)) {
                         newDist[distribution.variantID] = clone(distribution);
                    }
                });
            }
            this.localDistributions = newDist;
        },
        closeDialog() {
            this.$emit('update:visible', false);
        },
        selectVariant(checked, variant) {
            if (checked) {
                const distribution = Object.assign(
                    clone(DEFAULT_DISTRIBUTION),
                    {
                        variantKey: variant.key,
                        variantID: variant.id,
                        percent: 0, // Start with 0, user adjusts with slider
                    }
                );
                this.$set(this.localDistributions, variant.id, distribution);
            } else {
                this.$delete(this.localDistributions, variant.id);
            }
        },
        save() {
            if (!this.newDistributionIsValid) return;

            const finalDistributions = Object.values(this.localDistributions)
                .map(dist => {
                    let d = clone(dist);
                    delete d.id;
                    return d;
                })
                // Only include distributions with percent > 0 OR if they existed before (to allow setting to 0)
                .filter(dist => dist.percent > 0 || 
                               this.segment.distributions.some(orig => orig.variantID === dist.variantID));


            this.$emit('save-distribution', { 
                segmentId: this.currentSegment.id, 
                distributions: finalDistributions 
            });
        },
    },
    created() {
        // Initial setup if props are already available (e.g. if dialog is initially visible)
        if (this.visible && this.segment) {
            this.currentSegment = clone(this.segment);
            this.localVariants = clone(this.variants);
            this.initializeLocalDistributions();
        }
    }
};
</script>

<style scoped lang="less">
.distribution-variant-row {
    display: flex;
    align-items: center;
    margin-bottom: 15px;
}
.variant-info {
    display: flex;
    align-items: center;
    gap: 10px;
    width: 150px; /* Adjust as needed */
}
.slider-container {
    flex-grow: 1;
    margin-left: 20px;
}
.distribution-slider {
    width: 100%;
}
.width--full {
    width: 100%;
}
.save-button {
    margin-top: 20px;
}
.edit-distribution-alert {
    margin-top: 15px;
}
</style> 