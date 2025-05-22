<template>
    <el-dialog
        title="Create new variant"
        :visible.sync="isVisible"
        @close="closeDialog"
    >
        <div>
            <p>
                <el-input
                    placeholder="Variant key"
                    v-model="variantKey"
                ></el-input>
            </p>
            <el-button
                class="width--full"
                :disabled="!variantKey.trim()"
                @click.prevent="createAndClose"
                >Create Variant</el-button
            >
        </div>
    </el-dialog>
</template>

<script>
export default {
    name: 'CreateVariantDialog',
    props: {
        visible: {
            type: Boolean,
            default: false,
        },
    },
    data() {
        return {
            variantKey: '',
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
                this.variantKey = ''; // Reset key when dialog opens
            }
        }
    },
    methods: {
        closeDialog() {
            this.$emit('update:visible', false);
        },
        createAndClose() {
            if (this.variantKey.trim()) {
                this.$emit('create-variant', { key: this.variantKey });
                // Parent will be responsible for closing the dialog upon successful creation if desired
                // or we can close it immediately here:
                // this.closeDialog(); 
            }
        },
    },
};
</script>

<style scoped lang="less">
.width--full {
    width: 100%;
}
</style> 