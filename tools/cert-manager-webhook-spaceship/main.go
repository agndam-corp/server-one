package main

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"

	extapi "k8s.io/apiextensions-apiserver/pkg/apis/apiextensions/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	"github.com/cert-manager/cert-manager/pkg/acme/webhook/apis/acme/v1alpha1"
	"github.com/cert-manager/cert-manager/pkg/acme/webhook/cmd"
	certmanagermetav1 "github.com/cert-manager/cert-manager/pkg/apis/meta/v1"
)

var GroupName = os.Getenv("GROUP_NAME")

func main() {
	if GroupName == "" {
		panic("GROUP_NAME must be specified")
	}

	// This will register our custom DNS provider with the webhook serving
	// library, making it available as an API under the provided GroupName.
	cmd.RunWebhookServer(GroupName,
		&spaceshipDNSProviderSolver{},
	)
}

// spaceshipDNSProviderSolver implements the provider-specific logic needed to
// 'present' an ACME challenge TXT record for Spaceship DNS provider.
type spaceshipDNSProviderSolver struct {
	client kubernetes.Interface
}

// spaceshipDNSProviderConfig is a structure that is used to decode into when
// solving a DNS01 challenge.
type spaceshipDNSProviderConfig struct {
	APIKeyRef    certmanagermetav1.SecretKeySelector `json:"apiKeyRef"`
	APISecretRef certmanagermetav1.SecretKeySelector `json:"apiSecretRef"`
	BaseURL      string                              `json:"baseUrl"`
}

// Name is used as the name for this DNS solver when referencing it on the ACME
// Issuer resource.
func (c *spaceshipDNSProviderSolver) Name() string {
	return "spaceship"
}

// Present is responsible for actually presenting the DNS record with the
// DNS provider.
func (c *spaceshipDNSProviderSolver) Present(ch *v1alpha1.ChallengeRequest) error {
	cfg, err := loadConfig(ch.Config)
	if err != nil {
		return err
	}

	// Retrieve the API key and secret from Kubernetes secret
	apiKey, err := c.getSecretKey(&cfg, ch.ResourceNamespace, cfg.APIKeyRef)
	if err != nil {
		return fmt.Errorf("failed to get API key: %v", err)
	}

	apiSecret, err := c.getSecretKey(&cfg, ch.ResourceNamespace, cfg.APISecretRef)
	if err != nil {
		return fmt.Errorf("failed to get API secret: %v", err)
	}

	// Extract the domain and the record value from the challenge
	// ch.ResolvedFQDN will be in the format "_acme-challenge.subdomain.domain.com."
	// ch.Key will be the value for the TXT record
	fqdn := strings.TrimSuffix(ch.ResolvedFQDN, ".")
	recordValue := ch.Key

	// Extract the domain part (last two parts of the FQDN)
	// For example, if fqdn is "_acme-challenge.argocd.djasko.com", 
	// domain should be "djasko.com"
	parts := strings.Split(fqdn, ".")
	if len(parts) < 2 {
		return fmt.Errorf("invalid FQDN format: %s", fqdn)
	}
	
	domain := strings.Join(parts[len(parts)-2:], ".")     // "djasko.com"
	recordName := strings.Join(parts[:len(parts)-2], ".") // "_acme-challenge.argocd"

	// Create the DNS record
	err = c.createDNSRecord(cfg.BaseURL, apiKey, apiSecret, domain, recordName, recordValue)
	if err != nil {
		return fmt.Errorf("failed to create DNS record: %v", err)
	}

	return nil
}

// CleanUp should delete the DNS record that was created during the Present
// method.
func (c *spaceshipDNSProviderSolver) CleanUp(ch *v1alpha1.ChallengeRequest) error {
	cfg, err := loadConfig(ch.Config)
	if err != nil {
		return err
	}

	// Retrieve the API key and secret from Kubernetes secret
	apiKey, err := c.getSecretKey(&cfg, ch.ResourceNamespace, cfg.APIKeyRef)
	if err != nil {
		return fmt.Errorf("failed to get API key: %v", err)
	}

	apiSecret, err := c.getSecretKey(&cfg, ch.ResourceNamespace, cfg.APISecretRef)
	if err != nil {
		return fmt.Errorf("failed to get API secret: %v", err)
	}

	// Extract the domain and record name
	fqdn := strings.TrimSuffix(ch.ResolvedFQDN, ".")
	
	// Extract the parts
	parts := strings.Split(fqdn, ".")
	if len(parts) < 2 {
		return fmt.Errorf("invalid FQDN format: %s", fqdn)
	}
	
	domain := strings.Join(parts[len(parts)-2:], ".")     // "djasko.com"
	recordName := strings.Join(parts[:len(parts)-2], ".") // "_acme-challenge.argocd"

	// Delete the DNS record
	err = c.deleteDNSRecord(cfg.BaseURL, apiKey, apiSecret, domain, recordName)
	if err != nil {
		return fmt.Errorf("failed to delete DNS record: %v", err)
	}

	return nil
}

// Initialize will be called when the webhook first starts.
func (c *spaceshipDNSProviderSolver) Initialize(kubeClientConfig *rest.Config, stopCh <-chan struct{}) error {
	cl, err := kubernetes.NewForConfig(kubeClientConfig)
	if err != nil {
		return err
	}

	c.client = cl
	return nil
}

// loadConfig is a small helper function that decodes JSON configuration into
// the typed config struct.
func loadConfig(cfgJSON *extapi.JSON) (spaceshipDNSProviderConfig, error) {
	cfg := spaceshipDNSProviderConfig{}
	// handle the 'base case' where no configuration has been provided
	if cfgJSON == nil {
		return cfg, nil
	}
	if err := json.Unmarshal(cfgJSON.Raw, &cfg); err != nil {
		return cfg, fmt.Errorf("error decoding solver config: %v", err)
	}

	return cfg, nil
}

// getSecretKey retrieves a secret key from a Kubernetes secret
func (c *spaceshipDNSProviderSolver) getSecretKey(cfg *spaceshipDNSProviderConfig, namespace string, secretRef certmanagermetav1.SecretKeySelector) (string, error) {
	secretName := secretRef.Name
	secretKey := secretRef.Key
	
	// Get the secret from Kubernetes
	secret, err := c.client.CoreV1().Secrets(namespace).Get(context.TODO(), secretName, metav1.GetOptions{})
	if err != nil {
		return "", fmt.Errorf("failed to get secret %s/%s: %v", namespace, secretName, err)
	}
	
	// Extract the value from the secret
	value, ok := secret.Data[secretKey]
	if !ok {
		return "", fmt.Errorf("key %q not found in secret %s/%s", secretKey, namespace, secretName)
	}
	
	return string(value), nil
}

// createDNSRecord creates a DNS TXT record using the Spaceship API
func (c *spaceshipDNSProviderSolver) createDNSRecord(baseURL, apiKey, apiSecret, domain, recordName, recordValue string) error {
	url := fmt.Sprintf("%s/v1/dns/records/%s", baseURL, domain)
	
	// Prepare the request payload
	payload := map[string]interface{}{
		"data": []map[string]interface{}{
			{
				"name": recordName,
				"type": "TXT",
				"value": recordValue,
				"ttl": 60,
			},
		},
	}
	
	jsonData, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %v", err)
	}
	
	// Create the HTTP request
	req, err := http.NewRequest("POST", url, strings.NewReader(string(jsonData)))
	if err != nil {
		return fmt.Errorf("failed to create HTTP request: %v", err)
	}
	
	// Set headers
	// Use both API key and secret for authentication
	req.Header.Set("X-Api-Key", apiKey)
	req.Header.Set("X-Api-Secret", apiSecret)
	req.Header.Set("Content-Type", "application/json")
	
	// Log the request for debugging
	fmt.Printf("Sending request to %s\n", url)
	fmt.Printf("Request headers: X-Api-Key=[REDACTED], X-Api-Secret=[REDACTED], Content-Type=application/json\n")
	fmt.Printf("Request payload: %s\n", string(jsonData))
	
	// Send the request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send request: %v", err)
	}
	defer resp.Body.Close()
	
	// Log the response for debugging
	respBody, _ := io.ReadAll(resp.Body)
	fmt.Printf("Response status: %d\n", resp.StatusCode)
	fmt.Printf("Response body: %s\n", string(respBody))
	
	// Check the response
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		// Try a different authentication method if the first one fails
		if resp.StatusCode == 401 {
			fmt.Printf("Trying different authentication method\n")
			
			// Reset the request body
			req.Body = io.NopCloser(strings.NewReader(string(jsonData)))
			
			// Try using Basic auth with the API key and secret
			req.Header.Set("Authorization", "Basic "+base64.StdEncoding.EncodeToString([]byte(apiKey+":"+apiSecret)))
			
			// Send the request again
			resp, err = client.Do(req)
			if err != nil {
				return fmt.Errorf("failed to send request with basic auth: %v", err)
			}
			defer resp.Body.Close()
			
			// Log the response for debugging
			respBody, _ = io.ReadAll(resp.Body)
			fmt.Printf("Basic auth response status: %d\n", resp.StatusCode)
			fmt.Printf("Basic auth response body: %s\n", string(respBody))
			
			if resp.StatusCode < 200 || resp.StatusCode >= 300 {
				return fmt.Errorf("unexpected status code: %d, body: %s", resp.StatusCode, string(respBody))
			}
		} else {
			return fmt.Errorf("unexpected status code: %d, body: %s", resp.StatusCode, string(respBody))
		}
	}
	
	return nil
}

// deleteDNSRecord deletes a DNS TXT record using the Spaceship API
func (c *spaceshipDNSProviderSolver) deleteDNSRecord(baseURL, apiKey, apiSecret, domain, recordName string) error {
	url := fmt.Sprintf("%s/v1/dns/records/%s/%s/TXT", baseURL, domain, recordName)
	
	// Create the HTTP request
	req, err := http.NewRequest("DELETE", url, nil)
	if err != nil {
		return fmt.Errorf("failed to create HTTP request: %v", err)
	}
	
	// Set headers
	// Try using both API key and secret as authentication
	req.Header.Set("X-Api-Key", apiKey)
	req.Header.Set("X-Api-Secret", apiSecret)
	req.Header.Set("Content-Type", "application/json")
	
	// Log the request for debugging
	fmt.Printf("Sending DELETE request to %s\n", url)
	fmt.Printf("DELETE request headers: X-Api-Key=[REDACTED], X-Api-Secret=[REDACTED], Content-Type=application/json\n")
	
	// Send the request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send request: %v", err)
	}
	defer resp.Body.Close()
	
	// Log the response for debugging
	respBody, _ := io.ReadAll(resp.Body)
	fmt.Printf("DELETE response status: %d\n", resp.StatusCode)
	fmt.Printf("DELETE response body: %s\n", string(respBody))
	
	// Check the response
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("unexpected status code: %d, body: %s", resp.StatusCode, string(respBody))
	}
	
	return nil
}