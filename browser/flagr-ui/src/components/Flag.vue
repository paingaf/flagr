<template>
    <el-row>
        <el-col :span="20" :offset="2">
            <div class="container flag-container">
                <delete-flag-dialog
                    :visible.sync="dialogDeleteFlagVisible"
                    @confirm-delete="deleteFlag"
                ></delete-flag-dialog>

                <edit-distribution-dialog
                    :visible.sync="dialogEditDistributionOpen"
                    :segment="selectedSegment"
                    :variants="flag.variants"
                    @save-distribution="handleSaveDistributionFromDialog"
                ></edit-distribution-dialog>

                <create-segment-dialog
                    :visible.sync="dialogCreateSegmentOpen"
                    @create-segment="handleCreateSegmentFromDialog"
                ></create-segment-dialog>

                <el-dialog
                    title="Create new variant"
                    :visible.sync="dialogNewVariantVisible"
                >
                    <div>
                        <p>
                            <el-input
                                placeholder="Variant key"
                                v-model="newVariant.key"
                            ></el-input>
                        </p>
                        <el-button
                            class="width--full"
                            :disabled="!newVariant.key"
                            @click.prevent="createVariantAndCloseDialog"
                            >Create Variant</el-button
                        >
                    </div>
                </el-dialog>

                <create-variant-dialog
                    :visible.sync="dialogNewVariantVisible"
                    @create-variant="handleCreateVariantFromDialog"
                ></create-variant-dialog>

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
                            <categorization-tab
                                :chain-id.sync="chainId"
                                :dag-text.sync="dagText"
                                :selected-providers.sync="selectedProviders"
                                :selected-prompt.sync="selectedPrompt"
                                :providers="providers"
                                :prompts="prompts"
                                :chain-data="chainData"
                                :chain-data-loading="chainDataLoading"
                                :show-chain-data.sync="showChainData"
                                :prompt-text.sync="promptText"
                                :original-prompt-text="originalPromptText"
                                :new-prompt-name.sync="newPromptName"
                                :is-prompt-modified="isPromptModified"
                                :is-categorizing="isCategorizing"
                                :categorization-runs="categorizationRuns"
                                :expanded-runs.sync="expandedRuns"
                                :expanded-json.sync="expandedJson"
                                @provider-change="handleProviderChange"
                                @prompt-change="handlePromptChange"
                                @prompt-input="handlePromptInput"
                                @save-prompt="savePrompt"
                                @cancel-prompt-edit="cancelPromptEdit"
                                @run-categorization="runCategorization"
                                @clear-categorization-history="clearCategorizationHistory"
                                @expand-all-runs="expandAllRuns"
                                @collapse-all-runs="collapseAllRuns"
                                @run-expand="handleRunExpand"
                            ></categorization-tab>
                        </el-tab-pane>

                        <el-tab-pane label="Matching Scores">
                            <matching-scores-tab
                                :user-search-input.sync="userSearchInput"
                                :debounce-search-users="debounceSearchUsers"
                                :selected-user="selectedUser"
                                :show-user-data.sync="showUserData"
                                :chain-id.sync="chainId"
                                :chain-data="chainData"
                                :chain-data-loading="chainDataLoading"
                                :show-chain-data.sync="showChainData"
                                :dag-text.sync="dagText"
                                :selected-provider.sync="selectedProvider"
                                :providers="providers"
                                :selected-prompt.sync="selectedPrompt"
                                :prompts="prompts"
                                :prompt-text.sync="promptText"
                                :original-prompt-text="originalPromptText"
                                :new-prompt-name.sync="newPromptName"
                                :is-prompt-modified="isPromptModified"
                                :variants="flag.variants"
                                :is-any-variant-evaluating="isAnyVariantEvaluating"
                                :is-simulating="isSimulating"
                                :ab-test-result="abTestResult"
                                :loaded="loaded"
                                @user-select="handleUserSelect"
                                @provider-change="handleProviderChange"
                                @prompt-change="handlePromptChange"
                                @open-config="openConfig"
                                @prompt-input="handlePromptInput"
                                @save-prompt="savePrompt"
                                @cancel-prompt-edit="cancelPromptEdit"
                                @add-variant="dialogNewVariantVisible = true"
                                @save-variant="putVariant"
                                @delete-variant="deleteVariant"
                                @apply-config-to-variant="applyConfigToVariant"
                                @evaluate-variant="evaluateVariant"
                                @attachment-error="() => $message.error('Variant attachment is not valid')"
                                @show-message="(msg) => $message[msg.type](msg.message)"
                                @run-ab-test="runABTestSimulation"
                            ></matching-scores-tab>
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
import FlagHistory from '@/components/FlagHistory';
import { operators } from '@/operators.json';
import ConfigurationDrawer from './ConfigurationDrawer.vue';
import CreateVariantDialog from './CreateVariantDialog.vue';
import DeleteFlagDialog from './DeleteFlagDialog.vue';
import EditDistributionDialog from './EditDistributionDialog.vue';
import CreateSegmentDialog from './CreateSegmentDialog.vue';
import CategorizationTab from './CategorizationTab.vue';
import MatchingScoresTab from './MatchingScoresTab.vue';

const OPERATOR_VALUE_TO_LABEL_MAP = operators.reduce((acc, el) => {
    acc[el.value] = el.label;
    return acc;
}, {});

const { pluck, handleErr } = helpers;

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

function processSegment(segment) {
    segment.newConstraint = clone(DEFAULT_CONSTRAINT);
}

function processVariant(variant) {
    if (typeof variant.attachment === 'string') {
        variant.attachment = JSON.parse(variant.attachment);
    }
    variant.configStale = true;
}

// Helper function to remove UI-only properties before sending to backend
function sanitizeForBackend(data, uiOnlyProps = ['saveStatus']) {
    // Create a deep copy
    const sanitized = JSON.parse(JSON.stringify(data));
    
    // Process objects recursively
    const removeUIProps = (obj) => {
        if (!obj || typeof obj !== 'object') return;
        
        // Handle arrays
        if (Array.isArray(obj)) {
            obj.forEach(item => removeUIProps(item));
            return;
        }
        
        // Remove UI-only properties
        uiOnlyProps.forEach(prop => {
            if (Object.prototype.hasOwnProperty.call(obj, prop)) {
                delete obj[prop];
            }
        });
        
        // Process nested objects
        Object.values(obj).forEach(val => removeUIProps(val));
    };
    
    removeUIProps(sanitized);
    return sanitized;
}

export default {
    name: 'flag',
    components: {
        flagHistory: FlagHistory,
        ConfigurationDrawer,
        CreateVariantDialog,
        DeleteFlagDialog,
        EditDistributionDialog,
        CreateSegmentDialog,
        CategorizationTab,
        MatchingScoresTab,
    },
    data() {
        return {
            loaded: false,
            dialogDeleteFlagVisible: false,
            dialogEditDistributionOpen: false,
            dialogCreateSegmentOpen: false,
            dialogNewVariantVisible: false,
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
            expandedChainData: [],
            showUserData: false,
            expandedUserData: [],
        };
    },
    computed: {
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
        displayErrorNotification(baseMessage, error) {
            let detailSource = '';
            let specificDetail = '';

            if (error && error.response && error.response.data) {
                console.log('Backend error data:', error.response.data); 
                const errorData = error.response.data;

                if (errorData.message) {
                    specificDetail = errorData.message;
                    detailSource = 'Message';
                } else if (errorData.errorCode) {
                    specificDetail = errorData.errorCode;
                    detailSource = 'Error Code';
                } else if (errorData.details) {
                    specificDetail = errorData.details;
                    detailSource = 'Details';
                }
            } else if (error && error.message) {
                specificDetail = error.message;
                detailSource = 'Error';
            }

            let finalMessage = `${baseMessage}.`;
            if (specificDetail) {
                finalMessage += `\n${detailSource}: ${specificDetail}.`;
            } else {
                finalMessage += `\nAn unexpected error occurred.`;
            }
            finalMessage += '\nPlease check the browser console logs for more technical information.';

            this.$message.error({
                message: finalMessage,
                duration: 7000, 
                showClose: true,
            });

            if (!(error && error.response && error.response.data)) {
                console.error(`Full error details for "${baseMessage}":`, error);
            }
        },
        applyConfigToVariant(variant) {
            const currentConfig = this.$refs.configDrawer.config;
            console.log('>>> Flag.vue applyConfigToVariant: currentConfig from drawer:', JSON.parse(JSON.stringify(currentConfig)));

            if (!variant.attachment) {
                variant.attachment = {};
            }

            const configToApply = JSON.parse(JSON.stringify(currentConfig));

            variant.attachment = {
                ...variant.attachment,
                ...configToApply,
            };
            
            this.$set(variant, 'configStale', false);

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
                this.dialogDeleteFlagVisible = false;
            }, (err) => {
                handleErr.bind(this)(err); 
                this.dialogDeleteFlagVisible = false;
            });
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
        handleSaveDistributionFromDialog(payload) {
            const { segmentId, distributions } = payload;
            // The actual API call
            Axios.put(
                `${API_URL}/flags/${this.flagId}/segments/${segmentId}/distributions`,
                { distributions } // Payload from dialog is already formatted
            ).then((response) => {
                let updatedDistributions = response.data;
                // Update the original segment in the flag object
                const segmentInFlag = this.flag.segments.find(s => s.id === segmentId);
                if (segmentInFlag) {
                    segmentInFlag.distributions = updatedDistributions;
                }
                this.selectedSegment.distributions = updatedDistributions; // Also update selectedSegment if still used directly
                this.dialogEditDistributionOpen = false;
                this.$message.success('Distributions updated');
            }, handleErr.bind(this));
        },
        createVariant() {
            Axios.post(
                `${API_URL}/flags/${this.flagId}/variants`,
                this.newVariant
            ).then((response) => {
                let variant = response.data;
                processVariant(variant);
                this.newVariant = clone(DEFAULT_VARIANT);
                this.flag.variants.push(variant);
                this.$message.success('new variant created');
                this.dialogNewVariantVisible = false;
            }, (error) => {
                handleErr.bind(this)(error);
            });
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
            }, (error) => {
                handleErr.bind(this)(error);
            });
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
            }, (error) => {
                handleErr.bind(this)(error);
            });
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
            console.log('Selected user data:', user);
            this.selectedUser = user;
            this.userSearchInput = user.username;
            this.showUserData = true;
            this.markAllVariantsStale();
            
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
            this.markAllVariantsStale();
        },
        handleTweetUrlChange(value) {
            if (this.$refs.configDrawer) {
                const currentConfig = this.$refs.configDrawer.config;
                this.$refs.configDrawer.updateConfig({
                    ...currentConfig,
                    TWEET_URL: value,
                });
            }
            this.markAllVariantsStale();
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
            this.markAllVariantsStale();

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
            // Ensure config drawer is also updated with the original/cancelled text
            if (this.$refs.configDrawer) {
                const currentConfig = this.$refs.configDrawer.config;
                this.$refs.configDrawer.updateConfig({
                    ...currentConfig,
                    categoryMatchPrompt: this.originalPromptText,
                    promptId: this.prompts.find(p => p.content === this.originalPromptText)?._id || currentConfig.promptId
                });
            }
        },
        handlePromptChange(value) {
            const selectedPrompt = this.prompts.find((p) => p._id === value);
            if (selectedPrompt) {
                this.promptText = selectedPrompt.content;
                this.originalPromptText = selectedPrompt.content;
                this.isPromptModified = false;
                this.markAllVariantsStale();

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
                
                console.log('Sending evaluation request for matching scores:', {
                    url: '/simulation/relevance-score',
                    payload: variant.attachment
                });
                
                tgAxios.post(
                    '/simulation/relevance-score',
                    variant.attachment
                ).then((response) => {
                    console.log('Evaluation response:', response.data);
                    this.$set(variant, 'evaluationResult', response.data);
                    this.$message.success(
                        `Evaluation Score: ${response.data.score}`
                    );
                }).catch((err) => {
                    console.error('Error evaluating variant:', err);
                    this.displayErrorNotification('Failed to evaluate variant', err);
                }).finally(() => {
                    this.$set(variant, 'evaluating', false);
                    this.isAnyVariantEvaluating = this.flag.variants.some(v => v.evaluating);
                });
                
            } catch (error) {
                this.displayErrorNotification('Failed to evaluate variant', error);
                this.$set(variant, 'evaluating', false);
                this.isAnyVariantEvaluating = this.flag.variants.some(v => v.evaluating);
            }
        },
        async searchUsers(queryString, callback) {
            try {
                console.log('Searching for users with query:', queryString);
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
                console.log('User search response:', response.data);
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
                this.markAllVariantsStale();
            }
        },
        handleChainIdChange(value) {
            console.log(`>>> Flag.vue handleChainIdChange: Received value: "${value}". Current this.chainId (due to v-model): "${this.chainId}". Timestamp: ${new Date().toISOString()}`);
            if (this.flag && this.flag.key) {
                this.markAllVariantsStale();
            }

            if (this.$refs.configDrawer) {
                const currentConfig = this.$refs.configDrawer.config;
                this.$refs.configDrawer.updateConfig({
                    ...currentConfig,
                    CHAIN_ID: value,
                });
                console.log(`>>> Flag.vue handleChainIdChange: Updated configDrawer.config.CHAIN_ID to: "${value}"`);
            }
            
            console.log(`>>> Flag.vue handleChainIdChange: About to call debouncedFetchChainData. Current this.chainId: "${this.chainId}".`);
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
                    // Add save status field (default to false/pending)
                    result.saveStatus = false;
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
                    // Remove UI-only properties before sending to backend
                    const sanitizedRun = sanitizeForBackend(newRun);
                    
                    await tgAxios.post('/simulation/flagr/categorization-runs', {
                        flagId: this.flagId,
                        run: sanitizedRun
                    });
                    
                    // Update save status for all results in this run
                    newRun.results.forEach(result => {
                        result.saveStatus = true;
                    });
                    
                    this.$message.success('Categorization saved to database');
                } catch (error) {
                    console.error('Failed to save categorization run to database:', error);
                    // Keep the default false status for saveStatus
                    this.$message.warning('Failed to save categorization to database');
                    
                    // If we have pendingRuns in data, add this run to it
                    if (this.pendingRuns) {
                        this.pendingRuns.push(newRun);
                    }
                }
                
                this.$message.success('Categorization completed');
            } catch (error) {
                this.$message.error(`Failed to run categorization: \n ${error.response?.data?.errorCode || 'Unknown error'}`);
                console.error('Error running categorization:', error);
                console.error(error.response?.data);
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
            console.log(`>>> Flag.vue fetchChainData EXECUTING. Current this.chainId: "${this.chainId}". Timestamp: ${new Date().toISOString()}`);
            if (!this.chainId || this.chainId.trim() === '') {
                this.chainData = null;
                this.showChainData = false; // Ensure this is set
                console.log('>>> Flag.vue fetchChainData: chainId is empty, returning.');
                return;
            }
            
            this.chainDataLoading = true;
            try {
                console.log(`>>> Flag.vue fetchChainData: Attempting to fetch for ID: "${this.chainId}"`);
                const response = await tgAxios.get(`/tweet-chain/${this.chainId}`);
                console.log('Tweet chain response:', response.data);
                this.chainData = response.data;
                this.showChainData = true; // Show when data is fetched
            } catch (error) {
                console.error('Error fetching tweet chain data:', error);
                this.$message.error('Failed to fetch tweet chain data');
                this.chainData = null;
                this.showChainData = false; // Hide on error
            } finally {
                this.chainDataLoading = false;
            }
        },
        createVariantAndCloseDialog() {
            this.createVariant();
            this.dialogNewVariantVisible = false;
        },
        handleCreateSegmentFromDialog(segmentData) {
            this.newSegment.description = segmentData.description;
            this.newSegment.rolloutPercent = segmentData.rolloutPercent;
            this.createSegment();
        },
        markAllVariantsStale() {
            if (this.flag && this.flag.variants) {
                this.flag.variants.forEach(variant => {
                    this.$set(variant, 'configStale', true);
                });
            }
        },
    },
    async created() {
        this.debounceSearchUsers = debounce(this.searchUsers, 300);
        this.debounceSearchAuthors = debounce(this.searchAuthors, 300);
        this.debouncedFetchChainData = debounce(this.fetchChainData, 500);
    },
    watch: {
        chainId(newValue, oldValue) {
            console.log(`chainId changed:\n            Old value: ${oldValue}\n            New value: ${newValue}`);
            this.handleChainIdChange(newValue);
        },
        dagText(newValue, oldValue) {
            console.log(`dagText changed:\n            Old value: ${oldValue}\n            New value: ${newValue}`);
            this.handleTweetUrlChange(newValue);
        }
    },
    async mounted() {
        this.fetchFlag();
        this.loadAllTags();
        this.fetchTGUsers();
        this.fetchAuthors();
        await this.fetchLLMModels();
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
                this.categorizationRuns = response.data.map(item => {
                    const run = item.run || item;
                    
                    // Set saveStatus to true for all results in loaded runs
                    // (if it's in the database, it was saved successfully)
                    if (run.results && Array.isArray(run.results)) {
                        run.results.forEach(result => {
                            result.saveStatus = true;
                        });
                    }
                    
                    return run;
                });
                
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

                // Sync with what was already selected by fetchLLMModels instead of overriding
                if (this.selectedProviders.length > 0) {
                    newConfig.llmProvider = this.selectedProviders.join(',');
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

.width--full {
    width: 100%;
}

.variants-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

/* Styles moved to extracted components:
   - Categorization styles -> CategorizationTab, CategorizationResultsTable, CategorizationRunCollapse
   - Chain Data Styles -> ChainDataDisplay
   - User Data Styles -> UserDataDisplay  
   - Matching scores styles -> MatchingScoresTab
   - Table styles -> CategorizationRunCollapse
*/

</style>
