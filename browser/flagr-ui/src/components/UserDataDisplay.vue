<template>
    <el-collapse-transition>
        <div v-if="showData && user" class="user-data-container">
            <div class="result-header">
                <h4>User Details: {{ user.username }}</h4>
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
            
            <el-collapse v-model="internalExpandedUserData">
                <el-collapse-item name="user-data">
                    <template slot="title">
                        <div class="run-header-title">
                            <span>{{ user.username }}</span>
                            <span v-if="user.firstName || user.lastName">
                                - {{ user.firstName }} {{ user.lastName }}
                            </span>
                        </div>
                    </template>
                    
                    <el-card shadow="hover" class="user-data-card">
                        <div class="user-data-section">
                            <div class="user-header-info">
                                <div v-if="user.firstName"><strong>First Name:</strong> {{ user.firstName }}</div>
                                <div v-if="user.lastName"><strong>Last Name:</strong> {{ user.lastName }}</div>
                                <div v-if="user.bio"><strong>Bio:</strong> {{ user.bio }}</div>
                                <div v-if="user.email"><strong>Email:</strong> {{ user.email }}</div>
                                <div v-if="user.createdAt"><strong>Created:</strong> {{ formatDate(user.createdAt) }}</div>
                            </div>
                            
                            <div v-if="user.preferences" class="user-preferences-section">
                                <h5>User Preferences</h5>
                                <div class="user-preferences">
                                    <div v-for="(value, key) in user.preferences" :key="key" class="preference-item">
                                        <strong>{{ key }}:</strong> 
                                        <span v-if="Array.isArray(value)">{{ value.join(', ') }}</span>
                                        <span v-else-if="typeof value === 'object'">{{ JSON.stringify(value) }}</span>
                                        <span v-else>{{ value }}</span>
                                    </div>
                                </div>
                            </div>
                            
                            <div class="user-content-section">
                                <el-collapse>
                                    <el-collapse-item title="Raw User Data">
                                        <pre class="user-data-json">{{ JSON.stringify(user, null, 2) }}</pre>
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
    name: 'UserDataDisplay',
    props: {
        user: {
            type: Object,
            default: null,
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
            internalExpandedUserData: [],
        };
    },
    watch: {
        showData(newVal) {
            if (newVal && this.initiallyExpanded && this.user) {
                this.internalExpandedUserData = ['user-data'];
            } else if (!newVal) {
                this.internalExpandedUserData = [];
            }
        },
        user(newVal) {
            if (newVal && this.showData && this.initiallyExpanded) {
                this.internalExpandedUserData = ['user-data'];
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
        if (this.showData && this.initiallyExpanded && this.user) {
            this.internalExpandedUserData = ['user-data'];
        }
    }
};
</script>

<style scoped lang="less">
/* Copied from Flag.vue - consider moving to a global style sheet if used elsewhere */
.user-data-container {
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

.user-data-card {
    margin-top: 0;
    border-top: none;
}

.user-data-section {
    /* Container for all subsections */
}

.user-header-info {
    display: flex;
    flex-wrap: wrap;
    gap: 15px;
    margin-bottom: 15px;
}

.user-preferences-section {
    margin: 15px 0;
}

.user-preferences-section h5 {
    margin: 10px 0 5px; /* Adjusted from Flag.vue */
    font-size: 14px;
    color: #606266;
    padding: 0;
}

.user-preferences {
    background-color: #f5f7fa;
    border-radius: 4px;
    padding: 10px;
}

.preference-item {
    margin-bottom: 5px;
    word-break: break-word;
}

.user-content-section {
    margin-bottom: 15px; /* Matches general section spacing */
}

.user-data-json {
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