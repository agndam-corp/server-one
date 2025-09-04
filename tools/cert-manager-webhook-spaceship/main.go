package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strings"

	"github.com/cert-manager/cert-manager/pkg/acme/webhook/apis/acme/v1alpha1"
	"github.com/cert-manager/cert-manager/pkg/acme/webhook/cmd"
	certmanagermetav1 "github.com/cert-manager/cert-manager/pkg/apis/meta/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
)

var GroupName = os.Getenv("GROUP_NAME")

func main() {
	if GroupName == "" {
		panic("GROUP_NAME must be specified")
	}

	// This will register our custom DNS provider with the webhook serving
	// library, making it available as an API path.
	cmd.RunWebhookServer(GroupName,
		&spaceshipDNSProviderSolver{},
	)
}

// spaceshipDNSProviderSolver implements the provider-specific logic needed to
// 'present' an ACME challenge TXT record for your own DNS provider.
type spaceshipDNSProviderSolver struct {
	client kubernetes.Interface
}

// Name is used as the name for this DNS solver when referencing it on the ACME
// Issuer resource.
func (c *spaceshipDNSProviderSolver) Name() string {
	return "spaceship"
}

// Present is responsible for actually presenting the DNS record with the
// DNS provider.
func (c *spaceshipDNSProviderSolver) Present(ch *v1alpha1.ChallengeRequest) error {
	// Get the Spaceship.com API credentials from the Kubernetes secret
	apiKey, apiSecret, err := c.getApiCredentials(ch)
	if err != nil {
		return fmt.Errorf("failed to get Spaceship.com API credentials: %v", err)
	}

	// Extract the domain and key from the challenge request
	domain := ch.ResolvedFQDN
	key := ch.Key

	// Remove the trailing dot from the domain if present
	domain = strings.TrimSuffix(domain, ".")

	// Create the TXT record using Spaceship.com API
	err = c.createTXTRecord(apiKey, apiSecret, domain, key)
	if err != nil {
		return fmt.Errorf("failed to create TXT record: %v", err)
	}

	return nil
}

// CleanUp should delete the relevant TXT record from the DNS provider console.
func (c *spaceshipDNSProviderSolver) CleanUp(ch *v1alpha1.ChallengeRequest) error {
	// Get the Spaceship.com API credentials from the Kubernetes secret
	apiKey, apiSecret, err := c.getApiCredentials(ch)
	if err != nil {
		return fmt.Errorf("failed to get Spaceship.com API credentials: %v", err)
	}

	// Extract the domain and key from the challenge request
	domain := ch.ResolvedFQDN
	key := ch.Key

	// Remove the trailing dot from the domain if present
	domain = strings.TrimSuffix(domain, ".")

	// Delete the TXT record using Spaceship.com API
	err = c.deleteTXTRecord(apiKey, apiSecret, domain, key)
	if err != nil {
		return fmt.Errorf("failed to delete TXT record: %v", err)
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

// loadConfig is a small helper function that decodes the JSON configuration
// into the typed config struct.
func loadConfig(cfgJSON *certmanagermetav1.JSON) (spaceshipDNSProviderConfig, error) {
	cfg := spaceshipDNSProviderConfig{}
	// Handle the case where no configuration is provided
	if cfgJSON == nil {
		return cfg, nil
	}
	if err := json.Unmarshal(cfgJSON.Raw, &cfg); err != nil {
		return cfg, fmt.Errorf("error decoding solver config: %v", err)
	}

	return cfg, nil
}

// getApiCredentials retrieves the Spaceship.com API credentials from the Kubernetes secret
func (c *spaceshipDNSProviderSolver) getApiCredentials(ch *v1alpha1.ChallengeRequest) (string, string, error) {
	// Load the configuration
	cfg, err := loadConfig(ch.Config)
	if err != nil {
		return "", "", err
	}

	// Get the secret containing the API credentials
	secret, err := c.client.CoreV1().Secrets(ch.ResourceNamespace).Get(context.TODO(), cfg.APIKeySecretRef.Name, metav1.GetOptions{})
	if err != nil {
		return "", "", fmt.Errorf("failed to get API credentials secret %s: %v", cfg.APIKeySecretRef.Name, err)
	}

	// Get the API key from the secret
	apiKey, ok := secret.Data[cfg.APIKeySecretRef.Key]
	if !ok {
		return "", "", fmt.Errorf("API credentials secret %s did not contain key %s", cfg.APIKeySecretRef.Name, cfg.APIKeySecretRef.Key)
	}

	// Get the API secret from the secret
	apiSecret, ok := secret.Data[cfg.APISecretRef.Key]
	if !ok {
		return "", "", fmt.Errorf("API credentials secret %s did not contain key %s", cfg.APISecretRef.Name, cfg.APISecretRef.Key)
	}

	return string(apiKey), string(apiSecret), nil
}

// createTXTRecord creates a TXT record using the Spaceship.com API
func (c *spaceshipDNSProviderSolver) createTXTRecord(apiKey, apiSecret, domain, key string) error {
	// Parse the domain to get the root domain and subdomain
	rootDomain, subdomain := c.parseDomain(domain)
	
	// Prepare the request payload
	payload := map[string]interface{}{
		"items": []map[string]interface{}{
			{
				"type":  "TXT",
				"name":  subdomain,
				"ttl":   600,
				"address": key,
			},
		},
	}
	
	// Convert payload to JSON
	jsonPayload, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %v", err)
	}
	
	// Create HTTP request
	url := fmt.Sprintf("https://api.spaceship.com/v1/dns/records/%s", rootDomain)
	req, err := http.NewRequest("PUT", url, bytes.NewBuffer(jsonPayload))
	if err != nil {
		return fmt.Errorf("failed to create HTTP request: %v", err)
	}
	
	// Set headers
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-API-Key", apiKey)
	req.Header.Set("X-API-Secret", apiSecret)
	
	// Send request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send HTTP request: %v", err)
	}
	defer resp.Body.Close()
	
	// Check response status
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("Spaceship.com API returned status code %d", resp.StatusCode)
	}
	
	return nil
}

// deleteTXTRecord deletes a TXT record using the Spaceship.com API
func (c *spaceshipDNSProviderSolver) deleteTXTRecord(apiKey, apiSecret, domain, key string) error {
	// Parse the domain to get the root domain and subdomain
	rootDomain, subdomain := c.parseDomain(domain)
	
	// Prepare the request payload
	payload := []map[string]interface{}{
		{
			"type":  "TXT",
			"name":  subdomain,
			"address": key,
		},
	}
	
	// Convert payload to JSON
	jsonPayload, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %v", err)
	}
	
	// Create HTTP request
	url := fmt.Sprintf("https://api.spaceship.com/v1/dns/records/%s", rootDomain)
	req, err := http.NewRequest("DELETE", url, bytes.NewBuffer(jsonPayload))
	if err != nil {
		return fmt.Errorf("failed to create HTTP request: %v", err)
	}
	
	// Set headers
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-API-Key", apiKey)
	req.Header.Set("X-API-Secret", apiSecret)
	
	// Send request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send HTTP request: %v", err)
	}
	defer resp.Body.Close()
	
	// Check response status
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("Spaceship.com API returned status code %d", resp.StatusCode)
	}
	
	return nil
}

// parseDomain parses a full domain into root domain and subdomain
func (c *spaceshipDNSProviderSolver) parseDomain(domain string) (string, string) {
	// For ACME challenges, the domain will be in the format _acme-challenge.subdomain.example.com
	// We need to extract the root domain (example.com) and the subdomain (_acme-challenge.subdomain)
	
	parts := strings.Split(domain, ".")
	if len(parts) < 2 {
		return domain, ""
	}
	
	// For a domain like _acme-challenge.subdomain.example.com
	// Root domain would be example.com
	// Subdomain would be _acme-challenge.subdomain
	
	// Extract root domain (last two parts)
	rootDomain := strings.Join(parts[len(parts)-2:], ".")
	
	// Extract subdomain (everything before root domain)
	subdomain := strings.Join(parts[:len(parts)-2], ".")
	
	// If subdomain is empty, use "@"
	if subdomain == "" {
		subdomain = "@"
	}
	
	return rootDomain, subdomain
}

// spaceshipDNSProviderConfig is a structure that is used to decode into
// when loading the configuration from the API.
type spaceshipDNSProviderConfig struct {
	// APIKeySecretRef is a reference to a Secret containing the Spaceship.com API key
	APIKeySecretRef certmanagermetav1.SecretKeySelector `json:"apiKeySecretRef"`
	// APISecretRef is a reference to a Secret containing the Spaceship.com API secret
	APISecretRef certmanagermetav1.SecretKeySelector `json:"apiSecretRef"`
}