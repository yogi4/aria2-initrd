FROM ubuntu:20.04

# Install necessary packages
RUN apt-get update && \
    apt-get install -y python3 python3-pip tpm2-tools

# Install Flask
RUN pip3 install flask

# Copy the attestation server code
COPY attestation_server.py /app/attestation_server.py

# Expose port 5000
EXPOSE 5000

# Set the working directory
WORKDIR /app

# Run the attestation server
CMD ["python3", "attestation_server.py"]
