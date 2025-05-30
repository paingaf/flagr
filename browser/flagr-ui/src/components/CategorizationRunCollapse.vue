<template>
    <div class="categorization-run">
        <el-collapse 
            v-model="expandedRuns" 
            @change="$emit('run-expand', $event)"
        >
            <el-collapse-item :name="'run-' + (run.metadata && run.metadata.runNumber ? run.metadata.runNumber : 0)">
                <template slot="title">
                    <div class="run-header-title">
                        Run #{{ run.metadata && run.metadata.runNumber ? run.metadata.runNumber : 0 }} - {{ run.metadata && run.metadata.timestamp ? new Date(run.metadata.timestamp).toLocaleString() : 'Unknown date' }}
                    </div>
                </template>
                
                <el-table 
                    :data="run.results" 
                    style="width: 100%; margin-bottom: 20px;"
                    border
                    :fit="false"
                    resize-observer
                >
                    <el-table-column 
                        resizable
                        label="#" 
                        width="60"
                        prop="runNumber"
                    ></el-table-column>
                    
                    <el-table-column
                        resizable
                        label="Chain ID"
                        width="120"
                    >
                        <template>
                            {{ run.metadata && run.metadata.chainId ? run.metadata.chainId : 'N/A' }}
                        </template>
                    </el-table-column>
                    
                    <el-table-column
                        resizable
                        prop="modelName"
                        label="Model Name"
                        width="150"
                    ></el-table-column>
                    
                    <el-table-column
                        resizable
                        prop="startedAt"
                        label="Started At"
                        width="180"
                    >
                        <template slot-scope="scope">
                            {{ scope.row.startedAt ? new Date(scope.row.startedAt).toLocaleString() : 'N/A' }}
                        </template>
                    </el-table-column>
                    
                    <el-table-column
                        resizable
                        prop="totalCost"
                        label="Total Cost (Estimated)"
                        width="120"
                    >
                        <template slot-scope="scope">
                            {{ scope.row.totalCost ? scope.row.totalCost.toFixed(6) : '0' }}
                        </template>
                    </el-table-column>

                    <el-table-column
                        resizable
                        label="Input Tokens"
                        width="120"
                        align="center"
                    >
                        <template slot-scope="scope">
                            {{ scope.row.metadata?.inputTokens ?? 'N/A' }}
                        </template>
                    </el-table-column>

                    <el-table-column
                        resizable
                        label="Output Tokens"
                        width="130"
                        align="center"
                    >
                        <template slot-scope="scope">
                            {{ scope.row.metadata?.outputTokens ?? 'N/A' }}
                        </template>
                    </el-table-column>

                    <el-table-column
                        resizable
                        label="Total Tokens"
                        width="120"
                        align="center"
                    >
                        <template slot-scope="scope">
                            {{ scope.row.metadata?.totalTokens ?? 'N/A' }}
                        </template>
                    </el-table-column>

                    <el-table-column
                        resizable
                        label="Input Cost"
                        width="120"
                        align="center"
                    >
                        <template slot-scope="scope">
                            {{ typeof scope.row.metadata?.inputCost === 'number' ? scope.row.metadata.inputCost.toFixed(6) : 'N/A' }}
                        </template>
                    </el-table-column>

                    <el-table-column
                        resizable
                        label="Output Cost"
                        width="120"
                        align="center"
                    >
                        <template slot-scope="scope">
                            {{ typeof scope.row.metadata?.outputCost === 'number' ? scope.row.metadata.outputCost.toFixed(6) : 'N/A' }}
                        </template>
                    </el-table-column>

                    <el-table-column
                        resizable
                        prop="timeTakenMs"
                        label="Time (ms)"
                        width="120"
                    ></el-table-column>
                    
                    <el-table-column
                        resizable
                        label="DB Save"
                        width="80"
                        align="center"
                    >
                        <template slot-scope="scope">
                            <i v-if="scope.row.saveStatus" class="el-icon-check save-status-icon success"></i>
                            <i v-else class="el-icon-close save-status-icon failed"></i>
                        </template>
                    </el-table-column>
                    
                    <el-table-column 
                        resizable
                        label="Categories"
                        min-width="300"
                    >
                        <template slot-scope="scope">
                            <div
                                v-for="(categories, level) in scope.row.categoryResponse || {}"
                                :key="level"
                            >
                                <strong>{{ level }}:</strong>
                                {{ Array.isArray(categories) ? categories.join(', ') : categories }}
                            </div>
                            <div v-if="!scope.row.categoryResponse">No categories available</div>
                        </template>
                    </el-table-column>
                    
                    <el-table-column
                        resizable
                        label="Prompt Name"
                        width="150"
                    >
                        <template slot-scope="scope">
                            <div
                                style="
                                    white-space: pre-wrap;
                                    word-break: break-word;
                                "
                            >
                                {{
                                    scope.row.metadata && scope.row.metadata.promptName 
                                        ? (scope.row.metadata.promptName.length > 50
                                            ? scope.row.metadata.promptName.substring(0, 50) + '...'
                                            : scope.row.metadata.promptName)
                                        : 'No prompt name available'
                                }}
                            </div>
                        </template>
                    </el-table-column>
                </el-table>
                
                <div class="raw-response-section">
                    <div class="raw-response-header">
                        <h5>Raw Response</h5>
                    </div>
                    <el-collapse v-model="expandedJson">
                        <el-collapse-item :name="'json-' + (run.metadata && run.metadata.runNumber ? run.metadata.runNumber : 0)">
                            <pre class="result-json">{{ JSON.stringify(run.results, null, 2) }}</pre>
                        </el-collapse-item>
                    </el-collapse>
                </div>
            </el-collapse-item>
        </el-collapse>
        
        <el-divider v-if="runIndex < totalRuns - 1"></el-divider>
    </div>
</template>

<script>
export default {
    name: 'CategorizationRunCollapse',
    props: {
        run: {
            type: Object,
            required: true,
        },
        runIndex: {
            type: Number,
            required: true,
        },
        totalRuns: {
            type: Number,
            required: true,
        },
        expandedRuns: {
            type: Array,
            required: true,
        },
        expandedJson: {
            type: Array,
            required: true,
        },
    },
};
</script>

<style scoped>
.categorization-run {
    margin-bottom: 15px;
}

.run-header-title {
    font-weight: normal;
}

.raw-response-section {
    margin-top: 15px;
}

.raw-response-header h5 {
    margin: 10px 0;
    font-size: 14px;
    color: #606266;
}

.result-json {
    margin: 0;
    white-space: pre-wrap;
    word-wrap: break-word;
    background-color: #f5f7fa;
    padding: 10px;
    border-radius: 4px;
    font-family: monospace;
    font-size: 12px;
    max-height: 300px;
    overflow-y: auto;
}

.save-status-icon {
    font-size: 16px;
}

.save-status-icon.success {
    color: #67C23A;
}

.save-status-icon.failed {
    color: #F56C6C;
}

/* Custom styling for the collapse elements */
:deep(.el-collapse-item__header) {
    background-color: #f5f7fa;
    border-radius: 4px;
    padding: 0 10px;
    font-weight: normal;
}

:deep(.el-collapse-item__wrap) {
    background-color: #ffffff;
    border-radius: 0 0 4px 4px;
}

:deep(.raw-response-section .el-collapse-item__header) {
    background-color: #f9f9f9;
    padding: 0 10px;
    font-size: 13px;
    color: #909399;
}

/* Styles for resizable table columns */
:deep(.el-table__column-resize-proxy) {
    background-color: #409eff;
    width: 2px;
}

:deep(.el-table th.is-resizing) {
    background-color: #f5f7fa;
}

:deep(.el-table .cell) {
    word-break: break-word;
    line-height: 1.5;
}
</style> 