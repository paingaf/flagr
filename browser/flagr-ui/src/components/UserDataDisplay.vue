<template>
    <div v-if="showData && user" class="user-data-container">
        <div class="result-header clickable-header" @click="toggleExpanded">
            <h4>User Details: {{ user.username }}</h4>
            <div class="result-actions">
                <i :class="expandedIcon" class="expand-icon"></i>
            </div>
        </div>
        
        <el-collapse-transition>
            <div v-show="isExpanded">
                <el-card shadow="hover" class="user-data-card">
                    <div class="user-data-section">
                        <!-- Author-specific categories section -->
                        <div v-if="chainAuthorUsername && (authorSpecificCategories.hasCategories || alwaysShowRoot)" class="author-categories-section">
                            <h5>User Categories for {{ chainAuthorUsername }}</h5>
                            <div class="user-categories">
                                <div
                                    v-for="(categories, level) in displayableAuthorCategories"
                                    :key="level"
                                    class="category-level"
                                >
                                    <strong>{{ level }}:</strong>
                                    <span v-if="categories.length > 0">{{ categories.join(', ') }}</span>
                                    <span v-else class="no-categories-inline">(none)</span>
                                </div>
                            </div>
                        </div>

                        <div class="user-header-info">
                            <div v-if="user.firstName"><strong>First Name:</strong> {{ user.firstName }}</div>
                            <div v-if="user.lastName"><strong>Last Name:</strong> {{ user.lastName }}</div>
                            <div v-if="user.bio"><strong>Bio:</strong> {{ user.bio }}</div>
                            <div v-if="user.email"><strong>Email:</strong> {{ user.email }}</div>
                            <div v-if="user.createdAt"><strong>Created:</strong> {{ formatDate(user.createdAt) }}</div>
                        </div>
                        
                        <div v-if="extractedCategories.hasCategories || alwaysShowRoot" class="user-categories-section">
                            <h5>User Categories</h5>
                            <div class="user-categories">
                                <div
                                    v-for="(categories, level) in displayableCategories"
                                    :key="level"
                                    class="category-level"
                                >
                                    <strong>{{ level }}:</strong>
                                    <span v-if="categories.length > 0">{{ categories.join(', ') }}</span>
                                    <span v-else class="no-categories-inline">(none)</span>
                                </div>
                            </div>
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
            </div>
        </el-collapse-transition>
    </div>
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
        },
        chainData: {
            type: Object,
            default: null,
        }
    },
    data() {
        return {
            isExpanded: false,
        };
    },
    computed: {
        alwaysShowRoot() {
            return true; // Always show root level
        },
        expandedIcon() {
            return this.isExpanded ? 'el-icon-arrow-down' : 'el-icon-arrow-right';
        },
        chainAuthorUsername() {
            // Extract username directly from chainData
            if (this.chainData && this.chainData.username) {
                return this.chainData.username;
            }
            return null;
        },
        authorSpecificCategories() {
            if (!this.chainAuthorUsername || !this.user || !this.user.watchedAccounts || !Array.isArray(this.user.watchedAccounts)) {
                return { hasCategories: false, root: [], branch: [], leaf: [] };
            }

            const authorUsernameLower = this.chainAuthorUsername.toLowerCase();

            // Find the watched account for this specific author (case-insensitive)
            const watchedAccount = this.user.watchedAccounts.find(account => 
                account.username.toLowerCase() === authorUsernameLower
            );

            if (!watchedAccount || !watchedAccount.categories) {
                return { hasCategories: false, root: [], branch: [], leaf: [] };
            }

            const categoryLevels = {
                root: [],
                branch: [],
                leaf: []
            };

            // Extract categories for this specific author
            Object.keys(categoryLevels).forEach(level => {
                if (watchedAccount.categories[level] && Array.isArray(watchedAccount.categories[level])) {
                    categoryLevels[level] = watchedAccount.categories[level].map(category => category.name);
                }
            });

            // Check if there are any categories
            const hasCategories = Object.values(categoryLevels).some(level => level.length > 0);

            return {
                ...categoryLevels,
                hasCategories
            };
        },
        displayableAuthorCategories() {
            const allLevels = {
                root: [],
                branch: [],
                leaf: []
            };
            
            // Merge with actual categories, ensuring all levels are present
            const categoriesToDisplay = { ...allLevels, ...this.authorSpecificCategories };

            // Remove 'hasCategories' if it exists from the merge
            delete categoriesToDisplay.hasCategories;
            
            return categoriesToDisplay;
        },
        extractedCategories() {
            if (!this.user || !this.user.watchedAccounts || !Array.isArray(this.user.watchedAccounts)) {
                return { hasCategories: false, root: [], branch: [], leaf: [] };
            }

            const categoryLevels = {
                root: [],
                branch: [],
                leaf: []
            };

            // Extract categories from watchedAccounts
            this.user.watchedAccounts.forEach(account => {
                if (account.categories) {
                    // Process each category level
                    Object.keys(categoryLevels).forEach(level => {
                        if (account.categories[level] && Array.isArray(account.categories[level])) {
                            // Extract category names and add to the appropriate level
                            const categoryNames = account.categories[level].map(category => category.name);
                            categoryLevels[level].push(...categoryNames);
                        }
                    });
                }
            });

            // Remove duplicates from each level
            Object.keys(categoryLevels).forEach(level => {
                categoryLevels[level] = [...new Set(categoryLevels[level])];
            });

            // Check if there are any categories
            const hasCategories = Object.values(categoryLevels).some(level => level.length > 0);

            return {
                ...categoryLevels,
                hasCategories
            };
        },
        displayableCategories() {
            const allLevels = {
                root: [],
                branch: [],
                leaf: []
            };

            // Merge with actual categories, ensuring all levels are present
            const categoriesToDisplay = { ...allLevels, ...this.extractedCategories };

            // Remove 'hasCategories' if it exists from the merge
            delete categoriesToDisplay.hasCategories;
            
            return categoriesToDisplay;
        }
    },
    watch: {
        showData(newVal) {
            if (newVal && this.initiallyExpanded && this.user) {
                this.isExpanded = true;
            } else if (!newVal) {
                this.isExpanded = false;
            }
        },
        user(newVal) {
            if (newVal && this.showData && this.initiallyExpanded) {
                this.isExpanded = true;
            }
        }
    },
    methods: {
        formatDate(dateString) {
            if (!dateString) return 'N/A';
            return new Date(dateString).toLocaleString();
        },
        toggleExpanded() {
            this.isExpanded = !this.isExpanded;
        }
    },
    created() {
        if (this.showData && this.initiallyExpanded && this.user) {
            this.isExpanded = true;
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

.clickable-header {
    cursor: pointer;
    transition: background-color 0.2s;
}

.clickable-header:hover {
    background-color: #e9ecef;
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

.expand-icon {
    font-size: 16px;
    color: #606266;
    transition: transform 0.2s;
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

.author-categories-section {
    margin: 0 0 15px 0;
    padding-bottom: 15px;
    border-bottom: 1px solid #ebeef5;
}

.author-categories-section h5 {
    margin: 10px 0 5px;
    font-size: 14px;
    color: #606266;
    padding: 0;
}

.user-categories-section {
    margin: 15px 0;
}

.user-categories-section h5 {
    margin: 10px 0 5px;
    font-size: 14px;
    color: #606266;
    padding: 0;
}

.user-categories {
    background-color: #f5f7fa;
    border-radius: 4px;
    padding: 10px;
}

.category-level {
    margin-bottom: 8px;
    word-break: break-word;
}

.no-categories {
    color: #909399;
    font-style: italic;
}

.no-categories-inline {
    color: #909399;
    font-style: italic;
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