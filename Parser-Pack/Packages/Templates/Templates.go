package Templates

import "fmt"

// Declare variables
var wranglerJson string
var indexJs string
var nginxConf string

// BuildWranglerJSON function
func BuildWranglerJSON(teamserver string, worker string, workername string, customSecret string, header string, ts string, endpoint string, date string) string {
	wranglerJson += fmt.Sprintf(`/**
 * For more details on how to configure Wrangler, refer to:
 * https://developers.cloudflare.com/workers/wrangler/configuration/
 */
{
  "$schema": "node_modules/wrangler/config-schema.json",
  "name": "%s",
  "main": "src/index.js",
  "compatibility_date": "%s",
  "workers_dev": true,
  "observability": {
    "enabled": true
  },
  "vars": {
    "%s": "%s",
    "%s": "https://%s/",
    "%s": "https://%s/"	
  }
}`, workername, date, header, customSecret, ts, teamserver, endpoint, worker)

	return wranglerJson
}

// BuildIndexJS function
func BuildIndexJS(header string, ts string, endpoint string, customHeader string) string {
	indexJs += fmt.Sprintf(`const PRESHARED_AUTH_HEADER_KEY = "%s"

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event))
})

async function handleRequest(event) {
  const request = event.request
  
  const clonedRequest = request.clone()
  
  const path = request.url.replace(%s,"")
  const destUrl = %s + path 

  const psk = request.headers.get(PRESHARED_AUTH_HEADER_KEY)      

  if (psk === %s) {
    try {
      if (request.method === 'POST') {
        const response = await fetch(destUrl, {
          method: 'POST',
          headers: request.headers,
          body: clonedRequest.body,
        })
        
        return response
      } 
      else {
        const response = await fetch(destUrl, {
          method: 'GET',
          headers: request.headers
        })
        return response
      }
    } catch (error) {
      return new Response('Error forwarding request', { status: 500 })
    }
  } else {
    return new Response(JSON.stringify(
        {
          "Error" : "Authentication Failure."       
        }, null, 2), 
        {
          status: 401,
          headers: {
            "content-type": "application/json;charset=UTF-8"
          }
        }
    )
  } 
}`, customHeader, endpoint, ts, header)

	return indexJs
}

// BuildNginxConf function
func BuildNginxConf(customHeader string, customSecret string, port string, teamserver string) string {
	nginxConf += fmt.Sprintf(`server {
    listen 443 ssl;
    server_name %s;
    ssl_certificate /etc/letsencrypt/live/%s/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/%s/privkey.pem;
    ssl_protocols TLSv1.3;
    
    location / {
        if ($http_custom_header != "%s") {
            return 403;
        }
        proxy_pass https://localhost:%s;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header %s $http_custom_header;
    }
}
  
  `, teamserver, teamserver, teamserver, customSecret, port, customHeader)

	return nginxConf
}
