package main

import (
	"log"
	"os"
	"strconv"
	"tm1go/pkg/services"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/joho/godotenv"
)

func main() {
	// Load .env file
	err := godotenv.Load()
	if err != nil {
		log.Println("No .env file found, using system environment variables")
	}

	app := fiber.New()

	// Add middleware
	app.Use(logger.New())

	// Root endpoint
	app.Get("/", func(c *fiber.Ctx) error {
		return c.SendString("TM1 Go API with Fiber")
	})

	// Get TM1 connection parameters from environment
	address := os.Getenv("TM1_ADDRESS")
	portStr := os.Getenv("TM1_PORT")
	port, _ := strconv.Atoi(portStr)
	sslStr := os.Getenv("TM1_SSL")
	ssl, _ := strconv.ParseBool(sslStr)
	user := os.Getenv("TM1_USER")
	password := os.Getenv("TM1_PASSWORD")
	namespace := os.Getenv("TM1_NAMESPACE")
	database := os.Getenv("TM1_DATABASE")

	tm1Service, err := services.NewTM1Service(address, port, ssl, user, password, namespace, database)
	if err != nil {
		log.Fatalf("Failed to initialize TM1 service: %v", err)
	}

	// API Group
	api := app.Group("/api")

	// Cubes endpoints
	api.Get("/cubes", func(c *fiber.Ctx) error {
		names, err := tm1Service.Cubes.GetAllNames()
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.JSON(names)
	})

	api.Get("/cubes/:name", func(c *fiber.Ctx) error {
		name := c.Params("name")
		cube, err := tm1Service.Cubes.Get(name)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.JSON(cube)
	})

	// Dimensions endpoints
	api.Get("/dimensions", func(c *fiber.Ctx) error {
		names, err := tm1Service.Dimensions.GetAllNames()
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.JSON(names)
	})

	api.Get("/dimensions/:name", func(c *fiber.Ctx) error {
		name := c.Params("name")
		dim, err := tm1Service.Dimensions.Get(name)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.JSON(dim)
	})

	// Cells endpoints
	api.Post("/cells/execute-mdx", func(c *fiber.Ctx) error {
		var body struct {
			MDX string `json:"mdx"`
		}
		if err := c.BodyParser(&body); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
		}
		result, err := tm1Service.Cells.ExecuteMDX(body.MDX)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.JSON(result)
	})

	log.Fatal(app.Listen(":3000"))
}
