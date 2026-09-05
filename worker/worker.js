/**
 * OmniRoute Worker Proxy
 * 
 * This Worker proxies requests to OmniRoute running on VPS.
 * 
 * Environment Variables:
 * - OMNIRoute_URL: Base URL of OmniRoute (e.g., http://185.110.190.166:20128)
 * - API_KEY: Optional API key for authentication
 */

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const omnirouteUrl = env.OMNIRoute_URL || 'http://185.110.190.166:20128';
    
    // Build the target URL
    const targetUrl = new URL(url.pathname + url.search, omnirouteUrl);
    
    // Clone request headers
    const headers = new Headers(request.headers);
    
    // Add API key if configured
    if (env.API_KEY) {
      headers.set('Authorization', `Bearer ${env.API_KEY}`);
    }
    
    // Set proper host header
    headers.set('Host', new URL(omnirouteUrl).host);
    
    // Forward the request to OmniRoute
    try {
      const response = await fetch(targetUrl.toString(), {
        method: request.method,
        headers: headers,
        body: request.method !== 'GET' && request.method !== 'HEAD' ? request.body : undefined,
      });
      
      // Clone response headers
      const responseHeaders = new Headers(response.headers);
      
      // Add CORS headers for dashboard access
      responseHeaders.set('Access-Control-Allow-Origin', '*');
      responseHeaders.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
      responseHeaders.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
      
      // Handle preflight requests
      if (request.method === 'OPTIONS') {
        return new Response(null, {
          status: 204,
          headers: responseHeaders,
        });
      }
      
      // Return the proxied response
      return new Response(response.body, {
        status: response.status,
        headers: responseHeaders,
      });
    } catch (error) {
      return new Response(
        JSON.stringify({
          error: 'Proxy Error',
          message: error.message,
        }),
        {
          status: 503,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        }
      );
    }
  },
};