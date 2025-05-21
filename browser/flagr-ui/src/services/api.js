import Axios from 'axios';

// Create TG API instance with base URL
const tgAxios = Axios.create({
  // Use environment variable with a fallback for development
  baseURL: process.env.VUE_APP_TG_API_URL || 'http://localhost:3002'
});

// Add request interceptor to add API key to all requests
tgAxios.interceptors.request.use(config => {
  config.headers['x-api-key'] = process.env.VUE_APP_TG_API_KEY || '';
  
  // Log request details for debugging
  const fullUrl = `${config.baseURL || ''}${config.url || ''}`;
  console.log(`Outgoing Axios Request to: ${fullUrl}`, config);
  
  return config;
}, error => {
  // Also log request errors
  console.error('Axios Request Error:', error.config ? `Error for URL: ${error.config.baseURL || ''}${error.config.url || ''}` : 'Unknown URL', error);
  return Promise.reject(error);
});

export { tgAxios }; 