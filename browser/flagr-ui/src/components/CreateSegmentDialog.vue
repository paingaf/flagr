<template>
    <el-dialog
        title="Create segment"
        :visible.sync="isVisible"
        @close="closeDialog"
        width="40%" 
    >
        <div>
            <p>
                <el-input
                    placeholder="Segment description"
                    v-model="segmentDescription"
                ></el-input>
            </p>
            <p class="rollout-percent-p">
                <label class="el-form-item__label" style="width: auto;">Rollout Percent:</label>
                <el-slider
                    v-model="segmentRolloutPercent"
                    show-input
                    class="rollout-slider"
                ></el-slider>
            </p>
            <el-button
                class="width--full"
                :disabled="!segmentDescription.trim()"
                @click.prevent="create"
                >Create Segment</el-button
            >
        </div>
    </el-dialog>
</template>

<script>
const DEFAULT_SEGMENT_DESCRIPTION = '';
const DEFAULT_SEGMENT_ROLLOUT = 50;

export default {
    name: 'CreateSegmentDialog',
    props: {
        visible: {
            type: Boolean,
            default: false,
        },
    },
    data() {
        return {
            segmentDescription: DEFAULT_SEGMENT_DESCRIPTION,
            segmentRolloutPercent: DEFAULT_SEGMENT_ROLLOUT,
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
            }
        }
    },
    watch: {
        visible(newVal) {
            if (newVal) {
                // Reset form when dialog becomes visible
                this.segmentDescription = DEFAULT_SEGMENT_DESCRIPTION;
                this.segmentRolloutPercent = DEFAULT_SEGMENT_ROLLOUT;
            }
        }
    },
    methods: {
        closeDialog() {
            this.$emit('update:visible', false);
        },
        create() {
            if (this.segmentDescription.trim()) {
                this.$emit('create-segment', {
                    description: this.segmentDescription,
                    rolloutPercent: this.segmentRolloutPercent,
                });
            }
        },
    },
};
</script>

<style scoped lang="less">
.width--full {
    width: 100%;
    margin-top: 10px; /* Add some space above the button */
}
.rollout-slider {
    width: calc(100% - 120px); /* Adjust based on label width */
    display: inline-block;
    vertical-align: middle;
}
.rollout-percent-p {
    display: flex;
    align-items: center;
    gap: 10px;
}
.el-form-item__label {
    margin-bottom: 0; /* Override default Element UI label margin if needed */
}
</style> 