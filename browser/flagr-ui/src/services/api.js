import Axios from 'axios';

// Create TG API instance with base URL
const tgAxios = Axios.create({
  baseURL: process.env.VUE_APP_TG_API_URL
});

// Add request interceptor to add API key to all requests
tgAxios.interceptors.request.use(config => {
  config.headers['x-api-key'] = process.env.VUE_APP_TG_API_KEY;
  return config;
});

export { tgAxios }; 