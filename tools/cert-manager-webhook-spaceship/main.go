package main

import (
	"context"
	"encoding/json"
	"fmt"
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
	APIKeySecretRef certmanagermetav1.SecretKeySelector `json:"apiKeySecretRef"`
	BaseURL         string                              `json:"baseUrl"`
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

	// Retrieve the API key from Kubernetes secret
	apiKey, err := c.getApiKey(&cfg, ch.ResourceNamespace)
	if err != nil {
		return fmt.Errorf("failed to get API key: %v", err)
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
	err = c.createDNSRecord(cfg.BaseURL, apiKey, domain, recordName, recordValue)
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

	// Retrieve the API key from Kubernetes secret
	apiKey, err := c.getApiKey(&cfg, ch.ResourceNamespace)
	if err != nil {
		return fmt.Errorf("failed to get API key: %v", err)
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
	err = c.deleteDNSRecord(cfg.BaseURL, apiKey, domain, recordName)
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

// getApiKey retrieves the API key from a Kubernetes secret
func (c *spaceshipDNSProviderSolver) getApiKey(cfg *spaceshipDNSProviderConfig, namespace string) (string, error) {
	secretName := cfg.APIKeySecretRef.Name
	secretKey := cfg.APIKeySecretRef.Key
	
	// Get the secret from Kubernetes
	secret, err := c.client.CoreV1().Secrets(namespace).Get(context.TODO(), secretName, metav1.GetOptions{})
	if err != nil {
		return "", fmt.Errorf("failed to get secret %s/%s: %v", namespace, secretName, err)
	}
	
	// Extract the API key from the secret
	apiKey, ok := secret.Data[secretKey]
	if !ok {
		return "", fmt.Errorf("key %q not found in secret %s/%s", secretKey, namespace, secretName)
	}
	
	return string(apiKey), nil
}

// createDNSRecord creates a DNS TXT record using the Spaceship API
func (c *spaceshipDNSProviderSolver) createDNSRecord(baseURL, apiKey, domain, recordName, recordValue string) error {
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
	req.Header.Set("Authorization", "Bearer "+apiKey)
	req.Header.Set("Content-Type", "application/json")
	
	// Send the request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send request: %v", err)
	}
	defer resp.Body.Close()
	
	// Check the response
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}
	
	return nil
}

// deleteDNSRecord deletes a DNS TXT record using the Spaceship API
func (c *spaceshipDNSProviderSolver) deleteDNSRecord(baseURL, apiKey, domain, recordName string) error {
	url := fmt.Sprintf("%s/v1/dns/records/%s/%s/TXT", baseURL, domain, recordName)
	
	// Create the HTTP request
	req, err := http.NewRequest("DELETE", url, nil)
	if err != nil {
		return fmt.Errorf("failed to create HTTP request: %v", err)
	}
	
	// Set headers
	req.Header.Set("Authorization", "Bearer "+apiKey)
	req.Header.Set("Content-Type", "application/json")
	
	// Send the request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send request: %v", err)
	}
	defer resp.Body.Close()
	
	// Check the response
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}
	
	return nil
}