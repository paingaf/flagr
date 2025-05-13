<template>
    <el-row>
        <el-col :span="20" :offset="2">
            <div class="container flag-container">
                <el-dialog
                    title="Delete feature flag"
                    :visible.sync="dialogDeleteFlagVisible"
                >
                    <span
                        >Are you sure you want to delete this feature
                        flag?</span
                    >
                    <span slot="footer" class="dialog-footer">
                        <el-button @click="dialogDeleteFlagVisible = false"
                            >Cancel</el-button
                        >
                        <el-button type="primary" @click.prevent="deleteFlag"
                            >Confirm</el-button
                        >
                    </span>
                </el-dialog>

                <el-dialog
                    title="Edit distribution"
                    :visible.sync="dialogEditDistributionOpen"
                >
                    <div v-if="loaded && flag">
                        <div
                            v-for="variant in flag.variants"
                            :key="'distribution-variant-' + variant.id"
                        >
                            <div>
                                <el-checkbox
                                    @change="(e) => selectVariant(e, variant)"
                                    :checked="!!newDistributions[variant.id]"
                                ></el-checkbox>
                                <el-tag
                                    type="danger"
                                    :disable-transitions="true"
                                    >{{ variant.key }}</el-tag
                                >
                            </div>
                            <el-slider
                                v-if="!newDistributions[variant.id]"
                                :value="0"
                                :disabled="true"
                                show-input
                            ></el-slider>
                            <div v-if="!!newDistributions[variant.id]">
                                <el-slider
                                    v-model="
                                        newDistributions[variant.id].percent
                                    "
                                    :disabled="false"
                                    show-input
                                ></el-slider>
                            </div>
                        </div>
                    </div>
                    <el-button
                        class="width--full"
                        :disabled="!newDistributionIsValid"
                        @click.prevent="() => saveDistribution(selectedSegment)"
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

                <el-dialog
                    title="Create segment"
                    :visible.sync="dialogCreateSegmentOpen"
                >
                    <div>
                        <p>
                            <el-input
                                placeholder="Segment description"
                                v-model="newSegment.description"
                            ></el-input>
                        </p>
                        <p>
                            <el-slider
                                v-model="newSegment.rolloutPercent"
                                show-input
                            ></el-slider>
                        </p>
                        <el-button
                            class="width--full"
                            :disabled="!newSegment.description"
                            @click.prevent="createSegment"
                            >Create Segment</el-button
                        >
                    </div>
                </el-dialog>

                <el-breadcrumb separator="/">
                    <el-breadcrumb-item :to="{ name: 'home' }"
                        >Home page</el-breadcrumb-item
                    >
                    <el-breadcrumb-item
                        >Flag ID: {{ $route.params.flagId }}</el-breadcrumb-item
                    >
                </el-breadcrumb>

                <div v-if="loaded && flag">
                    <el-tabs>
                        <el-tab-pane label="Categorization">
                            <div class="categorization-container">
                                <div class="header-controls">
                                    <el-input
                                        v-model="chainId"
                                        placeholder="Enter Chain ID"
                                        class="chain-id-input"
                                        @input="handleChainIdChange"
                                    ></el-input>

                                    <div class="dag-input-group">
                                        <el-input
                                            v-model="dagText"
                                            placeholder="Enter tweet url"
                                            class="dag-text-input"
                                            @input="handleTweetUrlChange"
                                        ></el-input>
                                    </div>

                                    <el-select
                                        v-model="selectedProviders"
                                        placeholder="Select LLM Providers"
                                        class="model-select"
                                        multiple
                                        @change="handleProviderChange"
                                    >
                                        <el-option
                                            v-for="item in providers"
                                            :key="item.value"
                                            :label="item.label"
                                            :value="item.value"
                                        ></el-option>
                                    </el-select>

                                    <el-select
                                        v-model="selectedPrompt"
                                        placeholder="Select Prompt"
                                        class="prompt-select"
                                        @change="handlePromptChange"
                                    >
                                        <el-option
                                            v-for="item in prompts"
                                            :key="item._id"
                                            :label="item.name"
                                            :value="item._id"
                                        ></el-option>
                                    </el-select>
                                </div>

                                <!-- Chain Data Display -->
                                <el-collapse-transition>
                                    <div v-if="showChainData && chainData" class="chain-data-container">
                                        <div class="result-header">
                                            <h4>Tweet Chain Data: {{ chainId }}</h4>
                                            <div class="result-actions">
                                                <el-button 
                                                    size="small" 
                                                    @click="showChainData = false" 
                                                    type="text"
                                                >
                                                    Close
                                                </el-button>
                                            </div>
                                        </div>
                                        
                                        <el-collapse v-model="expandedChainData">
                                            <el-collapse-item name="chain-data">
                                                <template slot="title">
                                                    <div class="run-header-title">
                                                        <span>{{ chainData.username }}</span> - {{ new Date(chainData.createdAt).toLocaleString() }} - {{ chainData.chainType }}
                                                    </div>
                                                </template>
                                                
                                                <el-card v-loading="chainDataLoading" shadow="hover" class="chain-data-card">
                                                    <div class="chain-data-section">
                                                        <div class="chain-header-info">
                                                            <div><strong>Username:</strong> {{ chainData.username }}</div>
                                                            <div><strong>Created:</strong> {{ new Date(chainData.createdAt).toLocaleString() }}</div>
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
                                                                    <span><strong>Analyzed:</strong> {{ new Date(match.analyzedAt).toLocaleString() }}</span>
                                                                </div>
                                                            </div>
                                                        </div>
                                                        
                                                        <!-- Raw JSON Data -->
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

                                <div class="header-row">
                                    <div class="context-input-group">
                                        <el-input
                                            type="textarea"
                                            v-model="promptText"
                                            placeholder="Enter category match prompt"
                                            :rows="10"
                                            class="context-text-input"
                                            @input="handlePromptInput"
                                        ></el-input>

                                        <div
                                            v-if="isPromptModified"
                                            class="prompt-save-container"
                                        >
                                            <el-input
                                                v-model="newPromptName"
                                                placeholder="Enter prompt name"
                                                class="prompt-name-input"
                                            ></el-input>
                                            <div class="prompt-actions">
                                                <el-button
                                                    type="primary"
                                                    @click="savePrompt"
                                                    >Save New Prompt</el-button
                                                >
                                                <el-button
                                                    @click="cancelPromptEdit"
                                                    >Cancel</el-button
                                                >
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div class="submit-container">
                                    <div class="categorization-controls">
                                        <el-button
                                            type="primary"
                                            @click="runCategorization"
                                            :loading="isCategorizing"
                                            class="width--full"
                                        >
                                            Run Categorization
                                        </el-button>
                                        
                                        <el-button
                                            v-if="categorizationRuns.length > 0"
                                            type="danger"
                                            plain
                                            @click="clearCategorizationHistory"
                                            class="clear-history-button"
                                        >
                                            Clear History
                                        </el-button>
                                    </div>

                                    <div
                                        v-if="categorizationRuns.length"
                                        class="categorization-result"
                                    >
                                        <div class="result-header">
                                            <h4>Categorization Results</h4>
                                            <div class="result-actions">
                                                <el-button 
                                                    size="small" 
                                                    @click="expandAllRuns" 
                                                    type="text"
                                                >
                                                    Expand All
                                                </el-button>
                                                <el-button 
                                                    size="small" 
                                                    @click="collapseAllRuns" 
                                                    type="text"
                                                >
                                                    Collapse All
                                                </el-button>
                                            </div>
                                        </div>
                                        
                                        <div 
                                            v-for="(run, runIndex) in categorizationRuns" 
                                            :key="runIndex" 
                                            class="categorization-run"
                                        >
                                            <el-collapse 
                                                v-model="expandedRuns" 
                                                @change="handleRunExpand"
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
                                                    >
                                                        <el-table-column 
                                                            label="#" 
                                                            width="60"
                                                            prop="runNumber"
                                                        ></el-table-column>
                                                        
                                                        <el-table-column
                                                            prop="modelName"
                                                            label="Model Name"
                                                            width="150"
                                                        ></el-table-column>
                                                        
                                                        <el-table-column
                                                            prop="startedAt"
                                                            label="Started At"
                                                            width="180"
                                                        >
                                                            <template slot-scope="scope">
                                                                {{ scope.row.startedAt ? new Date(scope.row.startedAt).toLocaleString() : 'N/A' }}
                                                            </template>
                                                        </el-table-column>
                                                        
                                                        <el-table-column
                                                            prop="totalCost"
                                                            label="Total Cost"
                                                            width="120"
                                                        >
                                                            <template slot-scope="scope">
                                                                {{ scope.row.totalCost ? scope.row.totalCost.toFixed(4) : '0' }}
                                                            </template>
                                                        </el-table-column>
                                                        
                                                        <el-table-column
                                                            prop="timeTakenMs"
                                                            label="Time (ms)"
                                                            width="120"
                                                        ></el-table-column>
                                                        
                                                        <el-table-column label="Categories">
                                                            <template slot-scope="scope">
                                                                <div
                                                                    v-for="(
                                                                        categories, level
                                                                    ) in scope.row.categoryResponse || {}"
                                                                    :key="level"
                                                                >
                                                                    <strong
                                                                        >{{
                                                                            level
                                                                        }}:</strong
                                                                    >
                                                                    {{
                                                                        Array.isArray(categories) ? categories.join(', ') : categories
                                                                    }}
                                                                </div>
                                                                <div v-if="!scope.row.categoryResponse">No categories available</div>
                                                            </template>
                                                        </el-table-column>
                                                        
                                                        <el-table-column
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
                                            
                                            <el-divider v-if="runIndex < categorizationRuns.length - 1"></el-divider>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </el-tab-pane>

                        <el-tab-pane label="Matching Scores">
                            <div class="header-controls">
                                <el-autocomplete
                                    v-model="userSearchInput"
                                    :fetch-suggestions="debounceSearchUsers"
                                    placeholder="Search user by username"
                                    :trigger-on-focus="false"
                                    @select="handleUserSelect"
                                    value-key="username"
                                    class="user-select"
                                >
                                    <template slot-scope="{ item }">
                                        <div class="user-suggestion-item">
                                            <span>{{ item.username }}</span>
                                            <span
                                                style="
                                                    float: right;
                                                    color: #8492a6;
                                                    font-size: 13px;
                                                "
                                            >
                                                {{ item.firstName }}
                                            </span>
                                        </div>
                                    </template>
                                </el-autocomplete>

                                <el-input
                                    v-model="chainId"
                                    placeholder="Enter Chain ID"
                                    class="chain-id-input"
                                    @input="handleChainIdChange"
                                ></el-input>

                                <div class="dag-input-group">
                                    <el-input
                                        v-model="dagText"
                                        placeholder="Enter tweet url"
                                        class="dag-text-input"
                                        @input="handleTweetUrlChange"
                                    ></el-input>
                                </div>

                                <el-select
                                    v-model="selectedProvider"
                                    placeholder="Select LLM Provider"
                                    class="model-select"
                                    @change="handleProviderChange"
                                >
                                    <el-option
                                        v-for="item in providers"
                                        :key="item.value"
                                        :label="item.label"
                                        :value="item.value"
                                    ></el-option>
                                </el-select>

                                <el-select
                                    v-model="selectedPrompt"
                                    placeholder="Select Prompt"
                                    class="prompt-select"
                                    @change="handlePromptChange"
                                >
                                    <el-option
                                        v-for="item in prompts"
                                        :key="item._id"
                                        :label="item.name"
                                        :value="item._id"
                                    ></el-option>
                                </el-select>

                                <el-button
                                    class="config-button"
                                    @click="openConfig"
                                    type="primary"
                                    plain
                                >
                                    <i class="el-icon-setting"></i> Weights
                                </el-button>
                            </div>

                            <div class="header-row">
                                <div class="context-input-group">
                                    <el-input
                                        type="textarea"
                                        v-model="promptText"
                                        placeholder="Enter prompt (optional)"
                                        :rows="10"
                                        class="context-text-input"
                                        @input="handlePromptInput"
                                    ></el-input>

                                    <div
                                        v-if="isPromptModified"
                                        class="prompt-save-container"
                                    >
                                        <el-input
                                            v-model="newPromptName"
                                            placeholder="Enter prompt name"
                                            class="prompt-name-input"
                                        ></el-input>
                                        <div class="prompt-actions">
                                            <el-button
                                                type="primary"
                                                @click="savePrompt"
                                                >Save New Prompt</el-button
                                            >
                                            <el-button @click="cancelPromptEdit"
                                                >Cancel</el-button
                                            >
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <el-card class="variants-container">
                                <div slot="header" class="clearfix">
                                    <h2>Variants</h2>
                                </div>
                                <div
                                    class="variants-container-inner"
                                    v-if="flag.variants.length"
                                >
                                    <div
                                        v-for="variant in flag.variants"
                                        :key="variant.id"
                                    >
                                        <el-card shadow="hover">
                                            <el-form
                                                label-position="left"
                                                label-width="100px"
                                            >
                                                <div class="flex-row id-row">
                                                    <el-tag
                                                        type="primary"
                                                        :disable-transitions="
                                                            true
                                                        "
                                                    >
                                                        Variant ID:
                                                        <b>{{ variant.id }}</b>
                                                    </el-tag>
                                                    <el-input
                                                        class="variant-key-input"
                                                        size="small"
                                                        placeholder="Key"
                                                        v-model="variant.key"
                                                    >
                                                        <template slot="prepend"
                                                            >Key</template
                                                        >
                                                    </el-input>
                                                    <div
                                                        class="flex-row-right save-remove-variant-row"
                                                    >
                                                        <el-button
                                                            slot="append"
                                                            size="small"
                                                            @click="
                                                                putVariant(
                                                                    variant
                                                                )
                                                            "
                                                            >Save
                                                            Variant</el-button
                                                        >
                                                        <el-button
                                                            @click="
                                                                deleteVariant(
                                                                    variant
                                                                )
                                                            "
                                                            size="small"
                                                        >
                                                            <span
                                                                class="el-icon-delete"
                                                            />
                                                        </el-button>
                                                        <el-button
                                                            slot="append"
                                                            size="small"
                                                            @click="
                                                                applyConfigToVariant(
                                                                    variant
                                                                )
                                                            "
                                                            type="primary"
                                                            plain
                                                        >
                                                            Apply Configuration
                                                        </el-button>
                                                        <el-button
                                                            slot="append"
                                                            size="small"
                                                            @click="
                                                                evaluateVariant(
                                                                    variant
                                                                )
                                                            "
                                                            type="success"
                                                            plain
                                                            :loading="
                                                                variant.evaluating
                                                            "
                                                            :disabled="
                                                                variant.evaluating ||
                                                                isAnyVariantEvaluating ||
                                                                isSimulating
                                                            "
                                                        >
                                                            Evaluate
                                                        </el-button>
                                                    </div>
                                                </div>
                                                <el-collapse class="flex-row">
                                                    <el-collapse-item
                                                        title="Variant attachment"
                                                        class="variant-attachment-collapsable-title"
                                                    >
                                                        <p
                                                            class="variant-attachment-title"
                                                        >
                                                            You can add JSON in
                                                            key/value pairs
                                                            format.
                                                        </p>
                                                        <vue-json-editor
                                                            v-model="
                                                                variant.attachment
                                                            "
                                                            :showBtns="false"
                                                            :mode="'code'"
                                                            v-on:has-error="
                                                                variant.attachmentValid = false
                                                            "
                                                            v-on:input="
                                                                variant.attachmentValid = true
                                                            "
                                                            class="variant-attachment-content"
                                                        ></vue-json-editor>
                                                    </el-collapse-item>
                                                </el-collapse>
                                            </el-form>
                                        </el-card>

                                        <div
                                            v-if="variant.evaluationResult"
                                            class="evaluation-result"
                                        >
                                            <div class="evaluation-header">
                                                <h4>Evaluation Result</h4>
                                            </div>
                                            <pre class="evaluation-json">{{
                                                JSON.stringify(
                                                    variant.evaluationResult,
                                                    null,
                                                    2
                                                )
                                            }}</pre>
                                        </div>
                                    </div>
                                </div>

                                <div
                                    v-if="flag.variants.length >= 2"
                                    class="ab-test-simulation"
                                >
                                    <el-button
                                        type="primary"
                                        @click="runABTestSimulation"
                                        :loading="isSimulating"
                                        :disabled="
                                            isSimulating ||
                                            isAnyVariantEvaluating
                                        "
                                        class="width--full"
                                    >
                                        Run A/B Test Simulation
                                    </el-button>

                                    <div
                                        v-if="abTestResult"
                                        class="simulation-result"
                                    >
                                        <div class="simulation-header">
                                            <h4>A/B Test Simulation Result</h4>
                                        </div>
                                        <pre class="simulation-json">{{
                                            JSON.stringify(
                                                abTestResult,
                                                null,
                                                2
                                            )
                                        }}</pre>
                                    </div>
                                </div>
                            </el-card>

                            <spinner v-if="!loaded"></spinner>
                        </el-tab-pane>

                        <el-tab-pane label="History">
                            <flag-history
                                :flag-id="parseInt($route.params.flagId, 10)"
                            ></flag-history>
                        </el-tab-pane>
                    </el-tabs>
                </div>
                <configuration-drawer
                    ref="configDrawer"
                    @config-updated="handleConfigUpdate"
                />
            </div>
        </el-col>
    </el-row>
</template>

<script>
import clone from 'lodash.clone';
import Axios from 'axios';
import debounce from 'lodash/debounce';
import { tgAxios } from '@/services/api';

import constants from '@/constants';
import helpers from '@/helpers/helpers';
import Spinner from '@/components/Spinner';
import FlagHistory from '@/components/FlagHistory';
import vueJsonEditor from 'vue-json-editor';
import { operators } from '@/operators.json';
import ConfigurationDrawer from './ConfigurationDrawer.vue';

const OPERATOR_VALUE_TO_LABEL_MAP = operators.reduce((acc, el) => {
    acc[el.value] = el.label;
    return acc;
}, {});

const { sum, pluck, handleErr } = helpers;

const { API_URL, FLAGR_UI_POSSIBLE_ENTITY_TYPES } = constants;

const DEFAULT_SEGMENT = {
    description: '',
    rolloutPercent: 50,
};

const DEFAULT_CONSTRAINT = {
    operator: 'EQ',
    property: '',
    value: '',
};

const DEFAULT_VARIANT = {
    key: '',
};

const DEFAULT_TAG = {
    value: '',
};

const DEFAULT_DISTRIBUTION = {
    bitmap: '',
    variantID: 0,
    variantKey: '',
    percent: 0,
};

function processSegment(segment) {
    segment.newConstraint = clone(DEFAULT_CONSTRAINT);
}

function processVariant(variant) {
    if (typeof variant.attachment === 'string') {
        variant.attachment = JSON.parse(variant.attachment);
    }
}

export default {
    name: 'flag',
    components: {
        spinner: Spinner,
        flagHistory: FlagHistory,
        vueJsonEditor,
        ConfigurationDrawer,
    },
    data() {
        return {
            loaded: false,
            dialogDeleteFlagVisible: false,
            dialogEditDistributionOpen: false,
            dialogCreateSegmentOpen: false,
            entityTypes: [],
            allTags: [],
            allowCreateEntityType: true,
            tagInputVisible: false,
            flag: {
                createdBy: '',
                dataRecordsEnabled: false,
                entityType: '',
                description: '',
                enabled: false,
                id: 0,
                key: '',
                tags: [],
                segments: [],
                updatedAt: '',
                variants: [],
                notes: '',
            },
            newSegment: clone(DEFAULT_SEGMENT),
            newVariant: clone(DEFAULT_VARIANT),
            newTag: clone(DEFAULT_TAG),
            selectedSegment: null,
            newDistributions: {},
            operatorOptions: operators,
            operatorValueToLabelMap: OPERATOR_VALUE_TO_LABEL_MAP,
            showMdEditor: false,
            tgUsers: [],
            selectedUser: null,
            authors: [],
            selectedAuthor: null,
            dagText: '',
            isEvaluating: false,
            userSearchInput: '',
            authorSearchInput: '',
            promptText: '',
            debounceSearchUsers: null,
            debounceSearchAuthors: null,
            providers: [],
            providerObjects: [],
            selectedProviders: [],
            selectedProviderObjects: [],
            prompts: [],
            selectedPrompt: '',
            isSimulating: false,
            chainId: '',
            abTestResult: null,
            isCategorizing: false,
            categorizationResult: null,
            categorizationRuns: [],
            categorizationRunCount: 0,
            isAnyVariantEvaluating: false,
            isPromptModified: false,
            newPromptName: '',
            originalPromptText: '',
            selectedProvider: '',
            expandedRuns: [],
            expandedJson: [],
            pendingRuns: [],
            debouncedFetchChainData: null,
            chainData: null,
            chainDataLoading: false,
            showChainData: false,
            expandedChainData: ['chain-data'],
        };
    },
    computed: {
        newDistributionPercentageSum() {
            return sum(pluck(Object.values(this.newDistributions), 'percent'));
        },
        newDistributionIsValid() {
            const percentageSum = sum(
                pluck(Object.values(this.newDistributions), 'percent')
            );
            return percentageSum === 100;
        },
        flagId() {
            return this.$route.params.flagId;
        },
        editViewIcon() {
            return {
                'el-icon-edit': !this.showMdEditor,
                'el-icon-view': this.showMdEditor,
            };
        },
        toggleInnerConfigCard() {
            if (!this.showMdEditor && !this.flag.notes) {
                return 'flag-inner-config-card';
            } else {
                return '';
            }
        },
    },
    methods: {
        applyConfigToVariant(variant) {
            const currentConfig = this.$refs.configDrawer.config;

            if (!variant.attachment) {
                variant.attachment = {};
            }

            const configToApply = JSON.parse(JSON.stringify(currentConfig));

            variant.attachment = {
                ...variant.attachment,
                ...configToApply,
            };

            this.putVariant(variant);
        },
        handleConfigUpdate(newConfig) {
            console.log('Configuration updated:', newConfig);
        },
        deleteFlag() {
            const flagId = this.flagId;
            Axios.delete(`${API_URL}/flags/${this.flagId}`).then(() => {
                this.$router.replace({ name: 'home' });
                this.$message.success(`You deleted flag ${flagId}`);
            }, handleErr.bind(this));
        },
        putFlag(flag) {
            Axios.put(`${API_URL}/flags/${this.flagId}`, {
                description: flag.description,
                dataRecordsEnabled: flag.dataRecordsEnabled,
                key: flag.key || '',
                entityType: flag.entityType || '',
                notes: flag.notes || '',
            }).then(() => {
                this.$message.success(`Flag updated`);
            }, handleErr.bind(this));
        },
        setFlagEnabled(checked) {
            Axios.put(`${API_URL}/flags/${this.flagId}/enabled`, {
                enabled: checked,
            }).then(() => {
                const checkedStr = checked ? 'on' : 'off';
                this.$message.success(
                    `You turned ${checkedStr} this feature flag`
                );
            }, handleErr.bind(this));
        },
        selectVariant($event, variant) {
            const checked = $event;
            if (checked) {
                const distribution = Object.assign(
                    clone(DEFAULT_DISTRIBUTION),
                    {
                        variantKey: variant.key,
                        variantID: variant.id,
                    }
                );
                this.$set(this.newDistributions, variant.id, distribution);
            } else {
                this.$delete(this.newDistributions, variant.id);
            }
        },
        editDistribution(segment) {
            this.selectedSegment = segment;

            this.$set(this, 'newDistributions', {});

            segment.distributions.forEach((distribution) => {
                this.$set(
                    this.newDistributions,
                    distribution.variantID,
                    clone(distribution)
                );
            });

            this.dialogEditDistributionOpen = true;
        },
        saveDistribution(segment) {
            const distributions = Object.values(this.newDistributions)
                .filter((distribution) => distribution.percent !== 0)
                .map((distribution) => {
                    let dist = clone(distribution);
                    delete dist.id;
                    return dist;
                });

            Axios.put(
                `${API_URL}/flags/${this.flagId}/segments/${segment.id}/distributions`,
                { distributions }
            ).then((response) => {
                let distributions = response.data;
                this.selectedSegment.distributions = distributions;
                this.dialogEditDistributionOpen = false;
                this.$message.success('distributions updated');
            }, handleErr.bind(this));
        },
        createVariant() {
            Axios.post(
                `${API_URL}/flags/${this.flagId}/variants`,
                this.newVariant
            ).then((response) => {
                let variant = response.data;
                this.newVariant = clone(DEFAULT_VARIANT);
                this.flag.variants.push(variant);
                this.$message.success('new variant created');
            }, handleErr.bind(this));
        },
        deleteVariant(variant) {
            const isVariantInUse = this.flag.segments.some((segment) =>
                segment.distributions.some(
                    (distribution) => distribution.variantID === variant.id
                )
            );

            if (isVariantInUse) {
                alert(
                    'This variant is being used by a segment distribution. Please remove the segment or edit the distribution in order to remove this variant.'
                );
                return;
            }

            if (
                !confirm(
                    `Are you sure you want to delete variant #${variant.id} [${variant.key}]`
                )
            ) {
                return;
            }

            Axios.delete(
                `${API_URL}/flags/${this.flagId}/variants/${variant.id}`
            ).then(() => {
                this.$message.success('variant deleted');
                this.fetchFlag();
            }, handleErr.bind(this));
        },
        putVariant(variant) {
            if (variant.attachmentValid === false) {
                this.$message.error('variant attachment is not valid');
                return;
            }
            Axios.put(
                `${API_URL}/flags/${this.flagId}/variants/${variant.id}`,
                variant
            ).then(() => {
                this.$message.success('variant updated');
            }, handleErr.bind(this));
        },
        createTag() {
            Axios.post(
                `${API_URL}/flags/${this.flagId}/tags`,
                this.newTag
            ).then((response) => {
                let tag = response.data;
                this.newTag = clone(DEFAULT_TAG);
                if (
                    !this.flag.tags.map((tag) => tag.value).includes(tag.value)
                ) {
                    this.flag.tags.push(tag);
                    this.$message.success('new tag created');
                }
                this.tagInputVisible = false;
                this.loadAllTags();
            }, handleErr.bind(this));
        },
        cancelCreateTag() {
            this.newTag = clone(DEFAULT_TAG);
            this.tagInputVisible = false;
        },
        queryTags(queryString, cb) {
            let results = this.allTags.filter((tag) =>
                tag.value.toLowerCase().includes(queryString.toLowerCase())
            );
            cb(results);
        },
        loadAllTags() {
            Axios.get(`${API_URL}/tags`).then((response) => {
                let result = response.data;
                this.allTags = result;
            }, handleErr.bind(this));
        },
        showTagInput() {
            this.tagInputVisible = true;
            this.$nextTick(() => {
                this.$refs.saveTagInput.$refs.input.focus();
            });
        },
        deleteTag(tag) {
            if (!confirm(`Are you sure you want to delete tag #${tag.value}`)) {
                return;
            }

            Axios.delete(`${API_URL}/flags/${this.flagId}/tags/${tag.id}`).then(
                () => {
                    this.$message.success('tag deleted');
                    this.fetchFlag();
                    this.loadAllTags();
                },
                handleErr.bind(this)
            );
        },
        createConstraint(segment) {
            Axios.post(
                `${API_URL}/flags/${this.flagId}/segments/${segment.id}/constraints`,
                segment.newConstraint
            ).then((response) => {
                let constraint = response.data;
                segment.constraints.push(constraint);
                segment.newConstraint = clone(DEFAULT_CONSTRAINT);
                this.$message.success('new constraint created');
            }, handleErr.bind(this));
        },
        putConstraint(segment, constraint) {
            Axios.put(
                `${API_URL}/flags/${this.flagId}/segments/${segment.id}/constraints/${constraint.id}`,
                constraint
            ).then(() => {
                this.$message.success('constraint updated');
            }, handleErr.bind(this));
        },
        deleteConstraint(segment, constraint) {
            if (!confirm('Are you sure you want to delete this constraint?')) {
                return;
            }

            Axios.delete(
                `${API_URL}/flags/${this.flagId}/segments/${segment.id}/constraints/${constraint.id}`
            ).then(() => {
                const index = segment.constraints.findIndex(
                    (c) => c.id === constraint.id
                );
                segment.constraints.splice(index, 1);
                this.$message.success('constraint deleted');
            }, handleErr.bind(this));
        },
        putSegment(segment) {
            Axios.put(
                `${API_URL}/flags/${this.flagId}/segments/${segment.id}`,
                {
                    description: segment.description,
                    rolloutPercent: parseInt(segment.rolloutPercent, 10),
                }
            ).then(() => {
                this.$message.success('segment updated');
            }, handleErr.bind(this));
        },
        putSegmentsReorder(segments) {
            Axios.put(`${API_URL}/flags/${this.flagId}/segments/reorder`, {
                segmentIDs: pluck(segments, 'id'),
            }).then(() => {
                this.$message.success('segment reordered');
            }, handleErr.bind(this));
        },
        deleteSegment(segment) {
            if (!confirm('Are you sure you want to delete this segment?')) {
                return;
            }

            Axios.delete(
                `${API_URL}/flags/${this.flagId}/segments/${segment.id}`
            ).then(() => {
                const index = this.flag.segments.findIndex(
                    (el) => el.id === segment.id
                );
                this.flag.segments.splice(index, 1);
                this.$message.success('segment deleted');
            }, handleErr.bind(this));
        },
        createSegment() {
            Axios.post(
                `${API_URL}/flags/${this.flagId}/segments`,
                this.newSegment
            ).then((response) => {
                let segment = response.data;
                processSegment(segment);
                segment.constraints = [];
                this.newSegment = clone(DEFAULT_SEGMENT);
                this.flag.segments.push(segment);
                this.$message.success('new segment created');
                this.dialogCreateSegmentOpen = false;
            }, handleErr.bind(this));
        },
        fetchFlag() {
            Axios.get(`${API_URL}/flags/${this.flagId}`).then((response) => {
                let flag = response.data;
                flag.segments.forEach((segment) => processSegment(segment));
                flag.variants.forEach((variant) => processVariant(variant));
                this.flag = flag;
                this.loaded = true;
            }, handleErr.bind(this));
            this.fetchEntityTypes();
        },
        fetchEntityTypes() {
            function prepareEntityTypes(entityTypes) {
                let arr = entityTypes.map((key) => {
                    let label = key === '' ? '<null>' : key;
                    return { label: label, value: key };
                });
                if (entityTypes.indexOf('') === -1) {
                    arr.unshift({ label: '<null>', value: '' });
                }
                return arr;
            }

            if (
                FLAGR_UI_POSSIBLE_ENTITY_TYPES &&
                FLAGR_UI_POSSIBLE_ENTITY_TYPES != 'null'
            ) {
                let entityTypes = FLAGR_UI_POSSIBLE_ENTITY_TYPES.split(',');
                this.entityTypes = prepareEntityTypes(entityTypes);
                this.allowCreateEntityType = false;
                return;
            }

            Axios.get(`${API_URL}/flags/entity_types`).then((response) => {
                this.entityTypes = prepareEntityTypes(response.data);
            }, handleErr.bind(this));
        },
        toggleShowMdEditor() {
            this.showMdEditor = !this.showMdEditor;
        },
        openConfig() {
            this.$refs.configDrawer.showDrawer();
        },
        async fetchTGUsers() {
            try {
                const response = await tgAxios.get('/tg-users');
                this.tgUsers = response.data;
            } catch (error) {
                this.$message.error('Failed to fetch TG users');
                console.error('Error fetching TG users:', error);
            }
        },
        handleUserSelect(user) {
            this.selectedUser = user;
            this.userSearchInput = user.username;
            if (this.$refs.configDrawer) {
                const currentConfig = this.$refs.configDrawer.config;
                this.$refs.configDrawer.updateConfig({
                    ...currentConfig,
                    WEIGHTS: {
                        TYPE_WEIGHTS: currentConfig.WEIGHTS.TYPE_WEIGHTS,
                        INTERACTION_WEIGHTS:
                            currentConfig.WEIGHTS.INTERACTION_WEIGHTS,
                        THREAD_WEIGHTS: currentConfig.WEIGHTS.THREAD_WEIGHTS,
                        RELATIONSHIP_WEIGHTS:
                            currentConfig.WEIGHTS.RELATIONSHIP_WEIGHTS,
                        TIME_DECAY: currentConfig.WEIGHTS.TIME_DECAY,
                        MINIMUM_SCORE_THRESHOLD:
                            currentConfig.WEIGHTS.MINIMUM_SCORE_THRESHOLD,
                        ENABLE_EARLY_THRESHOLD_BREAK:
                            currentConfig.WEIGHTS.ENABLE_EARLY_THRESHOLD_BREAK,
                        COMPONENT_WEIGHTS:
                            currentConfig.WEIGHTS.COMPONENT_WEIGHTS,
                        HOP_PENALTY: currentConfig.WEIGHTS.HOP_PENALTY,
                    },
                    DAG: currentConfig.DAG,
                    TWEET_URL: currentConfig.TWEET_URL,
                    categoryMatchPrompt: currentConfig.categoryMatchPrompt,
                    llmProvider: currentConfig.llmProvider,
                    USER_PREFERENCES: user,
                });
            }
        },
        async fetchAuthors() {
            try {
                const response = await tgAxios.get(
                    '/categories/author-dags'
                );
                // Extract unique authors from the response
                this.authors = [
                    ...new Set(response.data.map((item) => item.author)),
                ];
            } catch (error) {
                this.$message.error('Failed to fetch authors');
                console.error('Error fetching authors:', error);
            }
        },
        handleAuthorChange(author) {
            if (this.$refs.configDrawer) {
                const currentConfig = this.$refs.configDrawer.config;
                this.$refs.configDrawer.updateConfig({
                    ...currentConfig,
                    DAG: author.value,
                });
            }
            this.authorSearchInput = author.value;
        },
        handleTweetUrlChange(value) {
            if (this.$refs.configDrawer) {
                const currentConfig = this.$refs.configDrawer.config;
                this.$refs.configDrawer.updateConfig({
                    ...currentConfig,
                    TWEET_URL: value,
                });
            }
        },
        handleContextChange(value) {
            if (this.$refs.configDrawer) {
                const currentConfig = this.$refs.configDrawer.config;
                this.$refs.configDrawer.updateConfig({
                    ...currentConfig,
                    categoryMatchPrompt: value,
                });
            }
        },
        handlePromptInput(value) {
            // Always check if the prompt has been modified, even if no prompt is selected
            this.isPromptModified = value !== this.originalPromptText;

            if (this.$refs.configDrawer) {
                const currentConfig = this.$refs.configDrawer.config;
                this.$refs.configDrawer.updateConfig({
                    ...currentConfig,
                    categoryMatchPrompt: value,
                    // Clear promptId when prompt is modified
                    promptId: this.isPromptModified
                        ? null
                        : currentConfig.promptId,
                });
            }
        },
        async savePrompt() {
            if (!this.newPromptName) {
                this.$message.error('Please enter a prompt name');
                return;
            }

            try {
                const response = await tgAxios.post('/prompts', {
                    content: this.promptText,
                    name: this.newPromptName,
                });

                this.$message.success('Prompt saved successfully');
                this.isPromptModified = false;
                this.newPromptName = '';
                this.originalPromptText = this.promptText;

                // Update config with new promptId
                if (this.$refs.configDrawer && response.data._id) {
                    const currentConfig = this.$refs.configDrawer.config;
                    this.$refs.configDrawer.updateConfig({
                        ...currentConfig,
                        promptId: response.data._id,
                    });
                }

                await this.fetchPrompts();
                // Set the newly created prompt as selected
                if (response.data._id) {
                    this.selectedPrompt = response.data._id;
                }
            } catch (error) {
                this.$message.error('Failed to save prompt');
                console.error('Error saving prompt:', error);
            }
        },
        cancelPromptEdit() {
            this.promptText = this.originalPromptText;
            this.isPromptModified = false;
            this.newPromptName = '';
            this.handleContextChange(this.originalPromptText);
        },
        handlePromptChange(value) {
            const selectedPrompt = this.prompts.find((p) => p._id === value);
            if (selectedPrompt) {
                this.promptText = selectedPrompt.content;
                this.originalPromptText = selectedPrompt.content;
                this.isPromptModified = false;

                // Update both prompt text and promptId in config
                if (this.$refs.configDrawer) {
                    const currentConfig = this.$refs.configDrawer.config;
                    this.$refs.configDrawer.updateConfig({
                        ...currentConfig,
                        categoryMatchPrompt: selectedPrompt.content,
                        promptId: selectedPrompt._id,
                    });
                }
            }
        },
        async evaluateVariant(variant) {
            try {
                if (!variant.attachment) {
                    this.$message.error('No configuration applied to evaluate');
                    return;
                }

                // Set loading states
                this.$set(variant, 'evaluating', true);
                this.isAnyVariantEvaluating = true;

                const response = await tgAxios.post(
                    '/simulation/relevance-score',
                    variant.attachment
                );

                this.$set(variant, 'evaluationResult', response.data);
                this.$message.success(
                    `Evaluation Score: ${response.data.score}`
                );
            } catch (error) {
                this.$message.error('Failed to evaluate variant');
                console.error('Error evaluating variant:', error);
            } finally {
                // Clear loading states
                this.$set(variant, 'evaluating', false);
                this.isAnyVariantEvaluating = false;
            }
        },
        async searchUsers(queryString, callback) {
            try {
                const response = await tgAxios.get(
                    '/tg-users/preferences',
                    {
                        params: {
                            ...(queryString &&
                                queryString.trim() !== '' && {
                                    username: queryString.trim(),
                                }),
                            limit: 10,
                        },
                    }
                );
                callback(response.data);
            } catch (error) {
                this.$message.error('Failed to fetch users');
                console.error('Error fetching users:', error);
                callback([]);
            }
        },
        async searchAuthors(queryString, callback) {
            try {
                const response = await tgAxios.get(
                    '/categories/author-dags',
                    {
                        params: {
                            ...(queryString &&
                                queryString.trim() !== '' && {
                                    search: queryString.trim(),
                                }),
                        },
                    }
                );
                // Map the response data to include just the author names
                const authors = response.data.map((item) => ({
                    value: item.author,
                }));
                console.log('Authors:', authors); // Debug log
                callback(authors);
            } catch (error) {
                this.$message.error('Failed to fetch authors');
                console.error('Error fetching authors:', error);
                callback([]);
            }
        },
        handleProviderChange(values) {
            if (this.$refs.configDrawer) {
                const currentConfig = this.$refs.configDrawer.config;
                const isMultipleSelect = Array.isArray(values);

                // For Categorization tab (multiple select)
                if (isMultipleSelect) {
                    // Store the selected names (for UI)
                    this.selectedProviders = values;
                    
                    // Map names to complete objects
                    this.selectedProviderObjects = values.map(name => 
                        this.providerObjects.find(obj => obj.name === name)
                    );
                    
                    this.$refs.configDrawer.updateConfig({
                        ...currentConfig,
                        llmProvider: values.join(','),
                    });
                }
                // For Matching Scores tab (single select)
                else {
                    // For single select, update both the name and object
                    this.selectedProvider = values;
                    
                    this.$refs.configDrawer.updateConfig({
                        ...currentConfig,
                        llmProvider: values,
                    });
                }
            }
        },
        handleChainIdChange(value) {
            if (this.$refs.configDrawer) {
                const currentConfig = this.$refs.configDrawer.config;
                this.$refs.configDrawer.updateConfig({
                    ...currentConfig,
                    CHAIN_ID: value,
                });
            }
            
            // Trigger debounced fetch of chain data
            this.debouncedFetchChainData();
        },
        async runABTestSimulation() {
            if (this.flag.variants.length < 2) {
                this.$message.error(
                    'Need at least 2 variants to run A/B test simulation'
                );
                return;
            }

            try {
                this.isSimulating = true;
                this.isAnyVariantEvaluating = true;
                const variantA = this.flag.variants[0];
                const variantB = this.flag.variants[1];

                const response = await tgAxios.post(
                    '/simulation/ab-test',
                    {
                        configA: variantA.attachment,
                        configB: variantB.attachment,
                    }
                );

                this.$set(variantA, 'simulationResult', response.data);
                this.$set(variantB, 'simulationResult', response.data);

                this.abTestResult = response.data;

                this.$message.success('A/B test simulation completed');
            } catch (error) {
                this.$message.error('Failed to run A/B test simulation');
                console.error('Error running A/B test simulation:', error);
            } finally {
                this.isSimulating = false;
                this.isAnyVariantEvaluating = false;
            }
        },
        async fetchLLMModels() {
            try {
                const response = await tgAxios.get('/llm/models');
                // API returns {models: [{name, provider, isDefault}, ...], currentProvider, currentModel}
                
                // Safely handle the API response - check if models array exists
                if (response.data && Array.isArray(response.data.models)) {
                    // Store complete model objects
                    this.providerObjects = response.data.models;
                    
                    // Create simplified objects for UI display
                    this.providers = response.data.models.map((model) => ({
                        label: model.name,
                        value: model.name,
                        isDefault: model.isDefault
                    }));
            
                    // Find default models
                    const defaultModels = this.providers
                        .filter(p => p.isDefault)
                        .map(p => p.value);
                    
                    if (defaultModels.length > 0) {
                        // Use API-provided defaults
                        this.selectedProviders = [defaultModels[0]];
                        // Set corresponding complete object
                        this.selectedProviderObjects = [
                            this.providerObjects.find(obj => obj.name === defaultModels[0])
                        ];
                        
                        if (this.$refs.configDrawer) {
                            const currentConfig = this.$refs.configDrawer.config;
                            this.$refs.configDrawer.updateConfig({
                                ...currentConfig,
                                llmProvider: defaultModels[0],
                            });
                        }
                    }
                } else {
                    console.error('Unexpected API response format:', response.data);
                    this.$message.warning('LLM models data format is unexpected');
                    this.providers = [];
                    this.providerObjects = [];
                }
            } catch (error) {
                this.$message.error('Failed to fetch LLM models');
                console.error('Error fetching LLM models:', error);
            }
        },
        async runCategorization() {
            this.isCategorizing = true;
            try {
                // Get the current selected prompt name
                let selectedPromptName = "Default";
                if (this.selectedPrompt) {
                    const promptObj = this.prompts.find(p => p._id === this.selectedPrompt);
                    if (promptObj) {
                        selectedPromptName = promptObj.name;
                    }
                }

                // Increment run counter
                this.categorizationRunCount++;
                const currentRunNumber = this.categorizationRunCount;

                // API expects objects with 'modelName' property instead of 'name'
                // Map the provider objects to the format expected by the API
                const mappedProviders = this.selectedProviderObjects.map(provider => ({
                    modelName: provider.name, // Transform 'name' to 'modelName' for API compatibility
                    provider: provider.provider,
                    isDefault: provider.isDefault
                    // Other properties from the original object are preserved
                }));

                const requestPayload = {
                    CHAIN_ID: this.chainId,
                    TWEET_URL: this.dagText,
                    categoryMatchPrompt: this.promptText,
                    llmProviders: mappedProviders,
                    promptId: this.selectedPrompt || null,
                };
                
                // Log the request payload for debugging
                console.log('Categorization request payload:', requestPayload);

                const response = await tgAxios.post(
                    '/simulation/categorization',
                    requestPayload
                );
                
                // Enhance results with run number and prompt information
                const enhancedResults = response.data.map(result => {
                    if (!result.metadata) {
                        result.metadata = {};
                    }
                    // Add promptName to metadata for display in table
                    result.metadata.promptName = selectedPromptName;
                    result.metadata.promptId = this.selectedPrompt || null;
                    // Add run number
                    result.runNumber = currentRunNumber;
                    
                    return result;
                });
                
                // Create a run metadata object
                const runMetadata = {
                    timestamp: new Date().toISOString(),
                    promptName: selectedPromptName,
                    chainId: this.chainId,
                    tweetUrl: this.dagText,
                    runNumber: currentRunNumber
                };
                
                // Create a new run object with deep clone to prevent reference issues
                const newRun = {
                    results: JSON.parse(JSON.stringify(enhancedResults)),
                    metadata: runMetadata
                };
                
                // Log the complete run structure for backend reference
                console.log('Categorization run structure for MongoDB:', {
                    flagId: this.flagId,
                    run: newRun
                });
                
                // Add to the beginning of the array (newest first)
                this.categorizationRuns.unshift(newRun);
                
                // For backward compatibility, also update categorizationResult
                this.categorizationResult = enhancedResults;
                
                // Expand the latest run by default
                if (!this.expandedRuns.includes('run-' + currentRunNumber)) {
                    this.expandedRuns.push('run-' + currentRunNumber);
                }
                
                // Save to MongoDB via TG API
                try {
                    await tgAxios.post('/simulation/flagr/categorization-runs', {
                        flagId: this.flagId,
                        run: newRun
                    });
                } catch (error) {
                    console.error('Failed to save categorization run to database:', error);
                    // If we have pendingRuns in data, add this run to it
                    if (this.pendingRuns) {
                        this.pendingRuns.push(newRun);
                    }
                }
                
                this.$message.success('Categorization completed');
            } catch (error) {
                this.$message.error('Failed to run categorization');
                console.error('Error running categorization:', error);
            } finally {
                this.isCategorizing = false;
            }
        },
        async fetchPrompts() {
            try {
                const response = await tgAxios.get('/prompts');
                this.prompts = response.data;

                // Find and select the "Default" prompt
                const defaultPrompt = this.prompts.find(
                    (p) => p.name === 'Default'
                );
                if (defaultPrompt) {
                    this.selectedPrompt = defaultPrompt._id;
                    this.promptText = defaultPrompt.content;
                    this.originalPromptText = defaultPrompt.content;
                    this.handleContextChange(defaultPrompt.content);
                }
            } catch (error) {
                this.$message.error('Failed to fetch prompts');
                console.error('Error fetching prompts:', error);
            }
        },
        async clearCategorizationHistory() {
            if (confirm("Are you sure you want to clear all categorization results?")) {
                try {
                    // Delete from MongoDB via TG API
                    await tgAxios.delete(`/simulation/flagr/categorization-runs/${this.flagId}`);
                    
                    // Clear local state
                    this.categorizationRuns = [];
                    this.categorizationResult = null;
                    this.categorizationRunCount = 0;
                    this.$message.success('Categorization history cleared');
                } catch (error) {
                    console.error('Failed to clear categorization history from database:', error);
                    // Still clear local state even if API call fails
                    this.categorizationRuns = [];
                    this.categorizationResult = null;
                    this.categorizationRunCount = 0;
                    this.$message.warning('Categorization history cleared locally but failed to clear from database');
                }
            }
        },
        expandAllRuns() {
            this.expandedRuns = this.categorizationRuns.map(run => {
                const runNumber = run.metadata && run.metadata.runNumber ? run.metadata.runNumber : 0;
                return 'run-' + runNumber;
            });
            this.expandedJson = this.categorizationRuns.map(run => {
                const runNumber = run.metadata && run.metadata.runNumber ? run.metadata.runNumber : 0;
                return 'json-' + runNumber;
            });
        },
        collapseAllRuns() {
            this.expandedRuns = [];
            this.expandedJson = [];
        },
        handleRunExpand(expandedNames) {
            console.log('Expanded runs:', expandedNames);
        },
        async syncPendingRuns() {
            if (!this.pendingRuns || this.pendingRuns.length === 0) return;
            
            const runsToSync = [...this.pendingRuns];
            this.pendingRuns = [];
            
            let failedCount = 0;
            
            for (const run of runsToSync) {
                try {
                    await tgAxios.post('/simulation/flagr/categorization-runs', {
                        flagId: this.flagId,
                        run: run
                    });
                } catch (error) {
                    failedCount++;
                    this.pendingRuns.push(run);
                    console.error('Failed to sync run:', error);
                }
            }
            
            if (failedCount > 0) {
                this.$message.warning(`${failedCount} runs failed to sync and will be retried later`);
            } else if (runsToSync.length > 0) {
                this.$message.success(`Successfully synced ${runsToSync.length} pending runs`);
            }
        },
        async fetchChainData() {
            if (!this.chainId || this.chainId.trim() === '') {
                this.chainData = null;
                this.showChainData = false;
                return;
            }
            
            this.chainDataLoading = true;
            try {
                console.log('Fetching tweet chain data for chain ID:', this.chainId);
                const response = await tgAxios.get(`/tweet-chain/${this.chainId}`);
                console.log('Tweet chain response:', response.data);
                this.chainData = response.data;
                this.showChainData = true;
            } catch (error) {
                console.error('Error fetching tweet chain data:', error);
                this.$message.error('Failed to fetch tweet chain data');
                this.chainData = null;
                this.showChainData = false;
            } finally {
                this.chainDataLoading = false;
            }
        },
    },
    async created() {
        this.debounceSearchUsers = debounce(this.searchUsers, 300);
        this.debounceSearchAuthors = debounce(this.searchAuthors, 300);
        this.debouncedFetchChainData = debounce(this.fetchChainData, 500);
    },
    async mounted() {
        this.fetchFlag();
        this.loadAllTags();
        this.fetchTGUsers();
        this.fetchAuthors();
        this.fetchLLMModels();
        this.fetchPrompts();

        // Try to sync any pending runs
        if (this.pendingRuns && this.pendingRuns.length > 0) {
            this.syncPendingRuns();
        }

        // Load categorization history from MongoDB
        try {
            const response = await tgAxios.get(`/simulation/flagr/categorization-runs/${this.flagId}`);
            console.log('GET /simulation/flagr/categorization-runs response:', {
                flagId: this.flagId,
                responseData: response.data,
                responseStatus: response.status,
                responseHeaders: response.headers
            });
            
            if (response.data && Array.isArray(response.data)) {
                // Extract the run objects from the nested structure
                this.categorizationRuns = response.data.map(item => item.run || item);
                
                if (this.categorizationRuns.length > 0) {
                    // Get the highest run number to continue counting from there
                    this.categorizationRunCount = Math.max(
                        ...this.categorizationRuns.map(run => 
                            run.metadata && run.metadata.runNumber 
                                ? run.metadata.runNumber 
                                : 0
                        ), 
                        0
                    );
                    
                    // Set the most recent run as the current result
                    this.categorizationResult = this.categorizationRuns[0].results;
                }
            }
        } catch (error) {
            console.error('Failed to load categorization history:', error);
        }

        try {
            const response = await tgAxios.get('/app-config');
            const data = response.data;

            // Initialize configuration with any existing values
            if (this.$refs.configDrawer) {
                const currentConfig = this.$refs.configDrawer.config;
                const newConfig = { ...currentConfig };

                // Set categoryMatchPrompt from API response
                if (data.categoryMatchPrompt) {
                    this.promptText = data.categoryMatchPrompt;
                    this.originalPromptText = data.categoryMatchPrompt;
                    newConfig.categoryMatchPrompt = data.categoryMatchPrompt;
                }

                // Set default provider
                const providers = Object.values(this.providers);
                if (providers.length > 0) {
                    this.selectedProviders = [providers[0].value];
                    newConfig.llmProvider = providers[0].value;
                }

                // Update configuration with all values at once
                this.$refs.configDrawer.updateConfig(newConfig);
            }
        } catch (error) {
            console.error('Error fetching app config:', error);
            this.$message.error('Failed to fetch app configuration');
        }
    },
};
</script>

<style lang="less">
h5 {
    padding: 0;
    margin: 10px 0 5px;
}

.grabbable {
    cursor: move; /* fallback if grab cursor is unsupported */
    cursor: grab;
    cursor: -moz-grab;
    cursor: -webkit-grab;
}

.flag-inner-config-card {
    .el-card__body {
        padding-bottom: 0px;
    }
}

.segment {
    .highlightable {
        padding: 4px;
        &:hover {
            background-color: #ddd;
        }
    }
    .segment-constraint {
        margin-bottom: 12px;
        padding: 1px;
        background-color: #f6f6f6;
        border-radius: 5px;
    }
    .distribution-card {
        height: 110px;
        text-align: center;
        .el-card__body {
            padding: 3px 10px 10px 10px;
        }
        font-size: 0.9em;
    }
}

ol.constraints-inner {
    background-color: white;
    padding-left: 8px;
    padding-right: 8px;
    border-radius: 3px;
    border: 1px solid #ddd;
    li {
        padding: 3px 0;
        .el-tag {
            font-size: 0.7em;
        }
    }
}

.constraints-inputs-container {
    padding: 5px 0;
}

.variants-container-inner {
    .el-card {
        margin-bottom: 1em;
    }
    .el-input-group__prepend {
        width: 2em;
    }
}

.segment-description-rollout {
    margin-top: 10px;
}

.edit-distribution-button {
    margin-top: 5px;
}

.edit-distribution-alert {
    margin-top: 10px;
}

.el-form-item {
    margin-bottom: 5px;
}

.id-row {
    margin-bottom: 8px;
}

.flag-config-card {
    .flag-content {
        margin-top: 8px;
        margin-bottom: -8px;
        .el-input-group__prepend {
            width: 8em;
        }
    }
    .data-records-label {
        margin-left: 3px;
        margin-bottom: 5px;
        margin-top: 6px;
        font-size: 0.65em;
        white-space: nowrap;
        vertical-align: middle;
    }
}

.variant-attachment-collapsable-title {
    margin: 0;
    font-size: 13px;
    color: #909399;
    width: 100%;
}

.variant-attachment-title {
    margin: 0;
    font-size: 13px;
    color: #909399;
}

.variant-key-input {
    margin-left: 10px;
    width: 50%;
}

.save-remove-variant-row {
    padding-bottom: 5px;
}

.tag-key-input {
    margin: 2.5px;
    width: 20%;
}

.tags-container-inner {
    margin-bottom: 10px;
}

.button-new-tag {
    margin: 2.5px;
}

.header-row {
    display: flex;
    justify-content: flex-end;
    align-items: center;
    margin-bottom: 20px;
    width: 100%;

    .context-input-group {
        width: 100%;
        margin-top: 20px;

        .context-text-input {
            width: 100%;
        }
    }
}

.header-controls {
    display: flex;
    align-items: center;
    gap: 15px;

    .user-select,
    .author-select,
    .model-select,
    .prompt-select {
        width: 200px;
    }

    .chain-id-input {
        width: 200px;
    }

    .dag-input-group {
        display: flex;
        gap: 10px;

        .dag-text-input {
            width: 400px;
        }
    }

    .config-button {
        margin-left: 0;
    }
}

.user-select {
    width: 200px;
    // margin-right: 10px;
}

.config-button {
    margin-left: 0;
}

.evaluation-result {
    margin-top: 15px;
    padding-top: 15px;
    border-top: 1px solid #dcdfe6;

    .evaluation-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 10px;

        h4 {
            margin: 0;
            color: #606266;
        }
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
}

.user-suggestion-item {
    padding: 4px 0;
}

.author-suggestion-item {
    padding: 4px 0;
}

.simulation-result {
    margin-top: 15px;
    padding: 10px;
    background-color: #f5f7fa;
    border-radius: 4px;
}

.simulation-header {
    margin-bottom: 8px;
}

.simulation-json {
    margin: 0;
    white-space: pre-wrap;
    word-wrap: break-word;
}

.ab-test-simulation {
    margin-top: 20px;
    padding: 10px;
    background-color: #f5f7fa;
    border-radius: 4px;
}

.categorization-container {
    padding: 20px;
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

.run-header-title {
    color: #606266;
    font-weight: bold;
    font-size: 14px;
}

.raw-response-section {
    margin-top: 15px;
    border-top: 1px dashed #ebeef5;
    padding-top: 15px;
}

.raw-response-header {
    margin-bottom: 10px;
}

.raw-response-header h5 {
    margin: 0;
    font-size: 14px;
    color: #606266;
}

.clear-history-button {
    min-width: 120px;
}

/* Custom styling for the collapse elements */
.categorization-run .el-collapse-item__header {
    background-color: #f5f7fa;
    border-radius: 4px;
    padding: 0 10px;
    font-weight: normal;
}

.categorization-run .el-collapse-item__wrap {
    background-color: #ffffff;
    border-radius: 0 0 4px 4px;
}

.result-json {
    margin: 0;
    white-space: pre-wrap;
    word-wrap: break-word;
}

.submit-container {
    margin-top: 10px;
}

.prompt-save-container {
    margin-top: 20px;
    display: flex;
    gap: 10px;
}

.prompt-name-input {
    width: 200px;
}

.prompt-actions {
    display: flex;
    gap: 10px;
}

.categorization-controls {
    display: flex;
    gap: 10px;
    margin-bottom: 15px;
}

.categorization-run {
    margin-bottom: 15px;
}

.raw-response-section .el-collapse-item__header {
    background-color: #f9f9f9;
    padding: 0 10px;
    font-size: 13px;
    color: #909399;
}

/* Chain Data Styles */
.chain-data-container {
    margin: 15px 0;
}

.chain-data-title {
    font-size: 16px;
    font-weight: bold;
    color: #303133;
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
    margin: 10px 0;
    font-size: 14px;
    color: #606266;
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

.chain-data-card {
    margin-top: 0;
    border-top: none;
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
