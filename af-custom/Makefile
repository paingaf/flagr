.PHONY: dev dev-stop

# Run both backend and frontend in development mode
dev:
	docker-compose -f docker-compose.dev.yml up -d && cd ../browser/flagr-ui && npm run serve -- --verbose

# Stop the backend container
dev-stop:
	docker-compose -f docker-compose.dev.yml down 