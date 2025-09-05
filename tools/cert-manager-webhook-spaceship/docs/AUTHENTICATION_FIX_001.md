# cert-manager Webhook for Spaceship DNS - Authentication Fix

## Problem

After deploying the cert-manager webhook for Spaceship DNS, certificate issuance was failing with the following error:

```
failed to create DNS record: unexpected status code: 401, body: {"detail":"Api key or secret not provided."}
```

## Root Cause

The webhook was not correctly sending the authentication headers to the Spaceship DNS API. The API requires both an API key and a secret to be sent as headers:

- `X-API-Key`: The Spaceship API key
- `X-API-Secret`: The Spaceship API secret

Additionally, the request format was incorrect. The API expects:

- A PUT request (not POST)
- An `items` field in the payload (not `data`)
- A `force: true` field in the payload

## Solution

### 1. Updated Authentication Headers

Modified the `createDNSRecord` function in `main.go` to use the correct headers:

```go
// Set headers as per documentation
req.Header.Set("X-API-Key", apiKey)
req.Header.Set("X-API-Secret", apiSecret)
req.Header.Set("Content-Type", "application/json")
```

### 2. Fixed Request Format

Updated the request payload to match the Spaceship API requirements:

```go
// Prepare the request payload with force and items fields as required by the API
payload := map[string]interface{}{
    "force": true,
    "items": []map[string]interface{}{
        {
            "name": recordName,
            "type": "TXT",
            "value": recordValue,
            "ttl": 60,
        },
    },
}
```

### 3. Used Correct HTTP Method

Changed from POST to PUT as required by the Spaceship API:

```go
// Create the HTTP request - using PUT as per documentation
req, err := http.NewRequest("PUT", url, strings.NewReader(string(jsonData)))
```

## Verification

After applying these fixes, sync the ArgoCD application to redeploy the webhook with the updated authentication. The certificate issuance should then proceed successfully.

You can verify the fix by checking the webhook pod logs:

```bash
kubectl logs -n cert-manager -l app=cert-manager-webhook-spaceship
```

You should see successful requests with 204 status codes:

```
Sending PUT request to https://spaceship.dev/api/v1/dns/records/djasko.com
Response status: 204
```

## Spaceship DNS API Documentation

The webhook uses the Spaceship DNS API:

- Create records: `PUT /v1/dns/records/{domain}`
- Delete records: `PUT /v1/dns/records/{domain}` (with empty items array)

Authentication is done via headers:
- `X-API-Key`: API key
- `X-API-Secret`: API secret