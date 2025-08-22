package main

import (
	"log"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"

	"server-go/handlers"
	"server-go/types"
)

func main() {
	// Create a new Fiber instance
	app := fiber.New()

	// Add a logger middleware
	app.Use(logger.New())

	//  Enable CORS for all origins
	app.Use(cors.New(cors.Config{
		AllowOrigins: "*", // allow all domains (change to specific origin for security)
		AllowHeaders: "Origin, Content-Type, Accept",
		AllowMethods: "GET,POST,PUT,DELETE,OPTIONS",
	}))
	// The defer for closing the pool should be in the db package
	// or handled with OS signals for graceful shutdown.

	// Define the API route and link it to the handler
	// Create a rule
	app.Post("/rules", func(c *fiber.Ctx) error {
		rule := new(types.Rule)
		if err := c.BodyParser(rule); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
		}
		handlers.Rules = append(handlers.Rules, *rule)
		return c.Status(201).JSON(rule)
	})

	// List rules
	app.Get("/rules", func(c *fiber.Ctx) error {
		return c.JSON(handlers.Rules)
	})

	// Evaluate a rule
	app.Post("/rules/:id/evaluate", func(c *fiber.Ctx) error {
		RuleID := c.Params("id")

		var payload map[string]interface{}

		if err := c.BodyParser(&payload); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
		}

		// Find rule by ID
		var found *types.Rule
		for i, r := range handlers.Rules {
			if r.ID == RuleID {
				found = &handlers.Rules[i]
				break
			}
		}

		if found == nil {
			return c.Status(404).JSON(fiber.Map{"error": "Rule not found"})
		}

		result := handlers.EvaluateRule(*found, payload)
		return c.JSON(fiber.Map{"result": result})
	})

	// Define a basic GET route
	app.Get("/", func(c *fiber.Ctx) error {
		return c.SendString("Hello from Fiber!")
	})

	// Define a GET route with a path parameter
	app.Get("/users/:name", func(c *fiber.Ctx) error {
		name := c.Params("name")
		return c.SendString("Hello, " + name + "!")
	})

	// Define a POST route
	app.Post("/data", func(c *fiber.Ctx) error {
		// Parse request body (e.g., JSON)
		var data map[string]interface{}
		if err := c.BodyParser(&data); err != nil {
			return c.Status(fiber.StatusBadRequest).SendString(err.Error())
		}
		log.Printf("Received data: %+v\n", data)
		return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "Data received successfully"})
	})

	// Start the server on port 3000
	log.Fatal(app.Listen(":4000"))
}
