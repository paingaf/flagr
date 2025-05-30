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

// Add response interceptor to log incoming responses and errors
tgAxios.interceptors.response.use(response => {
  // Log successful response details
  const requestConfig = response.config;
  const fullUrl = `${requestConfig.baseURL || ''}${requestConfig.url || ''}`;
  console.log(`Incoming Axios Response from: ${fullUrl}`, {
    status: response.status,
    statusText: response.statusText,
    headers: response.headers,
    data: response.data,
    requestConfig: requestConfig
  });
  return response;
}, error => {
  // Log error response details
  if (error.response) {
    // The request was made and the server responded with a status code
    // that falls out of the range of 2xx
    const requestConfig = error.response.config;
    const fullUrl = `${requestConfig.baseURL || ''}${requestConfig.url || ''}`;
    console.error(`Axios Response Error from: ${fullUrl}`, {
      status: error.response.status,
      statusText: error.response.statusText,
      headers: error.response.headers,
      data: error.response.data,
      requestConfig: requestConfig
    });
  } else if (error.request) {
    // The request was made but no response was received
    console.error('Axios No Response Error:', {
      request: error.request,
      message: error.message
    });
  } else {
    // Something happened in setting up the request that triggered an Error
    console.error('Axios General Error:', error.message, error);
  }
  return Promise.reject(error);
});

export { tgAxios }; 