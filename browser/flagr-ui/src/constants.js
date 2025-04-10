const API_URL = process.env.VUE_APP_API_URL;
const FLAGR_UI_POSSIBLE_ENTITY_TYPES =
    process.env.VUE_APP_FLAGR_UI_POSSIBLE_ENTITY_TYPES;
const TG_USERS_API = `${process.env.VUE_APP_TG_API_URL}/tg-users`;

export default {
    API_URL,
    FLAGR_UI_POSSIBLE_ENTITY_TYPES,
    TG_USERS_API,
};
