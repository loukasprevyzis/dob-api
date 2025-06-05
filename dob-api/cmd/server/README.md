## Features

- Connects to a PostgreSQL database using environment variables
- `/hello/` endpoint handled by the app
- `/hello/health` endpoint for health checks (useful for ALB/NLB)
- Loads environment variables from `.env` file if present

## Requirements

- Go 1.18+
- PostgreSQL database

## Environment Variables

The server expects the following environment variables:

```env
DB_HOST=your_db_host
DB_PORT=your_db_port
DB_USER=your_db_user
DB_PASSWORD=your_db_password
DB_NAME=your_db_name
```

>A .env file can be found in the project root to set these variables for local development.

### Install Go Dependencies

- `go mod tidy`

### Start the Application

- `go run main.go`
For more info:

```
REAMDE-DOCKER.MD
READDME-API.MD
```

