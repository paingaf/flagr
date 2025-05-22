<template>
    <el-collapse-transition>
        <div v-if="showData && chainData" class="chain-data-container">
            <div class="result-header">
                <h4>Tweet Chain Data: {{ chainId }}</h4>
                <div class="result-actions">
                    <el-button 
                        size="small" 
                        @click="handleClose" 
                        type="text"
                    >
                        Close
                    </el-button>
                </div>
            </div>
            
            <el-collapse v-model="internalExpandedChainData">
                <el-collapse-item name="chain-data">
                    <template slot="title">
                        <div class="run-header-title">
                            <span>{{ chainData.username }}</span> - {{ formatDate(chainData.createdAt) }} - {{ chainData.chainType }}
                        </div>
                    </template>
                    
                    <el-card v-loading="isLoading" shadow="hover" class="chain-data-card">
                        <div class="chain-data-section">
                            <div class="chain-header-info">
                                <div><strong>Username:</strong> {{ chainData.username }}</div>
                                <div><strong>Created:</strong> {{ formatDate(chainData.createdAt) }}</div>
                                <div><strong>Chain Type:</strong> {{ chainData.chainType }}</div>
                                <div v-if="chainData.isThread"><strong>Is Thread:</strong> Yes</div>
                                <div v-if="chainData.isComplete"><strong>Is Complete:</strong> Yes</div>
                            </div>
                            
                            <div class="chain-content-section">
                                <h5>Content</h5>
                                <div class="chain-content">{{ chainData.content }}</div>
                            </div>
                            
                            <div class="chain-content-section" v-if="chainData.chain && chainData.chain.length">
                                <h5>Chain ({{ chainData.chain.length }} items)</h5>
                                <div class="chain-items">
                                    <div v-for="(item, index) in chainData.chain" :key="index" class="chain-item">
                                        {{ item }}
                                    </div>
                                </div>
                            </div>
                            
                            <div class="chain-content-section" v-if="chainData.categoryMatches && chainData.categoryMatches.length">
                                <h5>Category Matches</h5>
                                <div v-for="(match, matchIndex) in chainData.categoryMatches" :key="matchIndex">
                                    <div v-if="match.categories">
                                        <div v-for="(categories, level) in match.categories" :key="level" class="category-level">
                                            <strong>{{ level }}:</strong>
                                            <div class="category-items">
                                                <el-tag 
                                                    v-for="category in categories" 
                                                    :key="category.id"
                                                    size="small"
                                                    type="info"
                                                    effect="plain"
                                                    class="category-tag"
                                                >
                                                    {{ category.name }}
                                                </el-tag>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="category-match-details">
                                        <span><strong>Prompt:</strong> {{ match.promptId || 'default' }}</span>
                                        <span><strong>Analyzed:</strong> {{ formatDate(match.analyzedAt) }}</span>
                                    </div>
                                </div>
                            </div>
                            
                            <div class="chain-content-section">
                                <el-collapse>
                                    <el-collapse-item title="Raw Chain Data">
                                        <pre class="chain-data-json">{{ JSON.stringify(chainData, null, 2) }}</pre>
                                    </el-collapse-item>
                                </el-collapse>
                            </div>
                        </div>
                    </el-card>
                </el-collapse-item>
            </el-collapse>
        </div>
    </el-collapse-transition>
</template>

<script>
export default {
    name: 'ChainDataDisplay',
    props: {
        chainId: {
            type: String,
            required: true,
        },
        chainData: {
            type: Object,
            default: null,
        },
        isLoading: {
            type: Boolean,
            default: false,
        },
        showData: { // Prop to control visibility from parent
            type: Boolean,
            default: false,
        },
        initiallyExpanded: {
            type: Boolean,
            default: true,
        }
    },
    data() {
        return {
            internalExpandedChainData: [],
        };
    },
    watch: {
        showData(newVal) {
            if (newVal && this.initiallyExpanded && this.chainData) {
                this.internalExpandedChainData = ['chain-data'];
            } else if (!newVal) {
                this.internalExpandedChainData = [];
            }
        },
        chainData(newVal) {
             if (newVal && this.showData && this.initiallyExpanded) {
                this.internalExpandedChainData = ['chain-data'];
            }
        }
    },
    methods: {
        formatDate(dateString) {
            if (!dateString) return 'N/A';
            return new Date(dateString).toLocaleString();
        },
        handleClose() {
            this.$emit('close');
        }
    },
    created() {
        if (this.showData && this.initiallyExpanded && this.chainData) {
            this.internalExpandedChainData = ['chain-data'];
        }
    }
};
</script>

<style scoped lang="less">
/* Copied from Flag.vue - consider moving to a global style sheet if used elsewhere */
.chain-data-container {
    margin: 15px 0;
}

.result-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
    padding: 10px;
    background-color: #f8f9fa;
    border-radius: 4px;
}

.result-header h4 {
    margin: 0;
    font-size: 16px;
    color: #303133;
}

.result-actions {
    display: flex;
    gap: 10px;
}

.run-header-title { /* Re-used class name, ensure it's styled appropriately or rename */
    color: #606266;
    font-weight: bold;
    font-size: 14px;
}

.chain-data-card {
    margin-top: 0;
    border-top: none;
}

.chain-data-section {
    /* Container for all subsections */
}

.chain-header-info {
    display: flex;
    flex-wrap: wrap;
    gap: 15px;
    margin-bottom: 15px;
}

.chain-content-section {
    margin-bottom: 15px;
}

.chain-content-section h5 {
    margin: 10px 0 5px; /* Adjusted from Flag.vue for consistency */
    font-size: 14px;
    color: #606266;
    padding: 0;
}

.chain-content {
    padding: 10px;
    background-color: #f5f7fa;
    border-radius: 4px;
    white-space: pre-wrap;
    word-break: break-word;
}

.chain-items {
    display: flex;
    flex-wrap: wrap;
    gap: 5px;
}

.chain-item {
    padding: 4px 8px;
    background-color: #f0f2f5;
    border-radius: 4px;
    font-size: 12px;
    font-family: monospace;
}

.category-level {
    margin-bottom: 8px;
}

.category-items {
    display: flex;
    flex-wrap: wrap;
    gap: 5px;
    margin-top: 4px;
}

.category-tag {
    margin-right: 5px;
}

.category-match-details {
    display: flex;
    justify-content: space-between;
    font-size: 12px;
    color: #909399;
    margin-top: 5px;
    margin-bottom: 15px;
    padding-bottom: 15px;
    border-bottom: 1px dashed #ebeef5;
}

.chain-data-json {
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