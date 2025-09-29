package main

import (
	"fmt"
	"log"
	"os"

	"github.com/agndam-corp/web-backend/database"
	"github.com/agndam-corp/web-backend/models"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

func main() {
	// Get database connection details from environment variables
	dbHost := getEnv("DB_HOST", "webapp-mariadb.webapp.svc.cluster.local")
	dbPort := getEnv("DB_PORT", "3306")
	dbUser := getEnv("DB_USER", "webapp-user")
	dbPassword := os.Getenv("DB_PASSWORD")
	dbName := getEnv("DB_NAME", "webapp-db")

	if dbPassword == "" {
		log.Fatal("DB_PASSWORD environment variable is required")
	}

	// Format connection string for MySQL/MariaDB
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local", dbUser, dbPassword, dbHost, dbPort, dbName)

	var err error
	database.DB, err = gorm.Open(mysql.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info), // Change to logger.Silent for production
	})
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	// Run migrations
	err = database.Migrate()
	if err != nil {
		log.Fatalf("Failed to run migrations: %v", err)
	}

	// Create sample instances
	sampleInstances := []models.AWSInstance{
		{
			Name:        "Primary VPN Server",
			InstanceID:  "i-1234567890abcdef0",
			Region:      "us-west-2",
			Description: "Primary VPN server in Oregon",
			Status:      "stopped",
			CreatedBy:   1, // Assuming admin user ID is 1
		},
		{
			Name:        "Backup VPN Server",
			InstanceID:  "i-0987654321fedcba0",
			Region:      "us-east-1",
			Description: "Backup VPN server in Virginia",
			Status:      "stopped",
			CreatedBy:   1, // Assuming admin user ID is 1
		},
		{
			Name:        "EU VPN Server",
			InstanceID:  "i-11111111111111111",
			Region:      "eu-west-1",
			Description: "European VPN server in Ireland",
			Status:      "stopped",
			CreatedBy:   1, // Assuming admin user ID is 1
		},
	}

	// Insert sample instances if they don't already exist
	for _, instance := range sampleInstances {
		var existingInstance models.AWSInstance
		if err := database.DB.Where("instance_id = ?", instance.InstanceID).First(&existingInstance).Error; err != nil {
			if err == gorm.ErrRecordNotFound {
				// Instance doesn't exist, create it
				if err := database.DB.Create(&instance).Error; err != nil {
					log.Printf("Failed to create instance %s: %v", instance.InstanceID, err)
				} else {
					log.Printf("Created instance %s", instance.InstanceID)
				}
			} else {
				log.Printf("Error checking for existing instance %s: %v", instance.InstanceID, err)
			}
		} else {
			log.Printf("Instance %s already exists", instance.InstanceID)
		}
	}

	log.Println("Sample instances initialization completed")
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}