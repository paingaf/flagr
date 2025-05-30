<template>
    <div class="categorization-result">
        <div class="result-header">
            <h4>Categorization Results</h4>
            <div class="result-actions">
                <el-button 
                    size="small" 
                    @click="$emit('expand-all')" 
                    type="text"
                >
                    Expand All
                </el-button>
                <el-button 
                    size="small" 
                    @click="$emit('collapse-all')" 
                    type="text"
                >
                    Collapse All
                </el-button>
            </div>
        </div>
        
        <categorization-run-collapse
            v-for="(run, runIndex) in categorizationRuns" 
            :key="runIndex"
            :run="run"
            :run-index="runIndex"
            :total-runs="categorizationRuns.length"
            :expanded-runs="expandedRuns"
            :expanded-json="expandedJson"
            @run-expand="$emit('run-expand', $event)"
        ></categorization-run-collapse>
    </div>
</template>

<script>
import CategorizationRunCollapse from './CategorizationRunCollapse.vue';

export default {
    name: 'CategorizationResultsTable',
    components: {
        CategorizationRunCollapse,
    },
    props: {
        categorizationRuns: {
            type: Array,
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
.result-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 15px;
}

.result-actions {
    display: flex;
    gap: 10px;
}
</style> 