# Dockerfile for TPM Attestation Server

FROM golang:1.22-alpine

# Install required packages for TPM2-tools
RUN apk add --no-cache bash tpm2-tools

# Set the working directory
WORKDIR /app

# Copy Go module files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy the application source
COPY main.go ./

# Build the application
RUN go build -o tpm-attestation-server

# Expose the application port
EXPOSE 5000

# Start the server
CMD ["./tpm-attestation-server"]
