# dob-api Docker Setup

This project includes a multi-stage Dockerfile to build and run the `dob-api` Go application efficiently.

## Dockerfile Explanation

### Build Stage
- Uses the official `golang:1.24-alpine` image for a lightweight Go build environment.
- Installs `git` to support Go module downloads.
- Copies `go.mod` and `go.sum` to download dependencies.
- Copies the entire project source.
- Builds a statically linked Linux binary `dob-api` from the `./cmd/server` package with `CGO_ENABLED=0` for maximum portability.

### Final Stage
- Uses the minimal `alpine:latest` image for a small final image size.
- Installs `ca-certificates` needed for HTTPS requests.
- Creates a non-root user `appuser` in group `appgroup` for security best practices.
- Copies the built binary from the builder stage.
- Changes ownership of the binary to `appuser`.
- Switches to running as `appuser`.
- Exposes port 8080.
- Sets the default command to run the `dob-api` binary.

## How to Build and Run Locally

**Build the Docker image**

```bash
docker build -t dob-api .
```

**Run the container**

```bash
docker run --rm -p 8080:8080 dob-api
```

**Access the API**

Open your browser or use `curl`:

```
http://localhost:8080/hello/{username}
```

## Note: Cross-Platform Build (Apple Silicon, CI, etc.)

If you are on a non-Linux machine (e.g., macOS with Apple Silicon) or want to ensure compatibility with Linux servers, build using:

```bash
docker buildx build --platform linux/amd64 -t dob-api .
```

## How to Push the Image to AWS ECR

**Authenticate Docker to ECR**

```bash
aws ecr get-login-password --region <your-region> \
  | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<your-region>.amazonaws.com
```

**Tag the image**

```bash
docker tag dob-api:latest <aws_account_id>.dkr.ecr.<your-region>.amazonaws.com/dob-api:latest
```

**Push the image**

```bash
docker push <aws_account_id>.dkr.ecr.<your-region>.amazonaws.com/dob-api:latest
```


>>Note: All steps above mentioned for local testing are handled by CICD too.