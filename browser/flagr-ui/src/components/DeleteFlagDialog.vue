<template>
    <el-dialog
        title="Delete feature flag"
        :visible.sync="isVisible"
        @close="closeDialog"
        width="30%"
    >
        <span>Are you sure you want to delete this feature flag?</span>
        <span slot="footer" class="dialog-footer">
            <el-button @click="closeDialog">Cancel</el-button>
            <el-button type="primary" @click.prevent="confirm">Confirm</el-button>
        </span>
    </el-dialog>
</template>

<script>
export default {
    name: 'DeleteFlagDialog',
    props: {
        visible: {
            type: Boolean,
            default: false,
        },
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
    methods: {
        closeDialog() {
            this.$emit('update:visible', false);
        },
        confirm() {
            this.$emit('confirm-delete');
            // The parent will be responsible for closing the dialog on success/failure if needed,
            // or after the action is completed.
        },
    },
};
</script>

<style scoped lang="less">
/* Add any specific styles for this dialog if needed */
.dialog-footer {
    text-align: right;
}
</style> 