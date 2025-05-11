package Templates

import (
	"fmt"
)

// Declare variables
var wranglerJson string
var indexJs string

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
  
  // Check if the method is GET or POST
  if (request.method !== 'GET' && request.method !== 'POST') {
    return new Response(JSON.stringify(
      {
        "Error": "Method not allowed."
      }, null, 2),
      {
        status: 405,
        headers: {
          "content-type": "application/json;charset=UTF-8",
          "Allow": "GET, POST"
        }
      }
    )
  }
  
  const clonedRequest = request.clone()
  
  const path = request.url.replace(%s, "")
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
      else if (request.method === 'GET') {
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
