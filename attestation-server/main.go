package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strings"
)

// AttestationRequest represents the data sent by the client
type AttestationRequest struct {
	Message   string `json:"message"`
	Signature string `json:"signature"`
	Nonce     string `json:"nonce"`
	PubKey    string `json:"pubkey"`
	PCRValues string `json:"pcr_values"`
}

// AttestationResponse represents the server's response
type AttestationResponse struct {
	Status  string `json:"status"`
	Message string `json:"message"`
}

// PCRBaseline defines the expected PCR values (configured by the admin)
var PCRBaseline map[string]string

// LoadPCRBaseline loads the expected PCR values from a JSON file
func LoadPCRBaseline(filePath string) error {
	data, err := ioutil.ReadFile(filePath)
	if err != nil {
		return fmt.Errorf("failed to read PCR baseline file: %v", err)
	}
	err = json.Unmarshal(data, &PCRBaseline)
	if err != nil {
		return fmt.Errorf("failed to parse PCR baseline file: %v", err)
	}
	return nil
}

// VerifyPCRs compares the received PCR values with the expected baseline
func VerifyPCRs(receivedPCRs string) (bool, string) {
	// Parse received PCRs
	pcrMap := make(map[string]string)
	lines := strings.Split(receivedPCRs, "\n")
	for _, line := range lines {
		if parts := strings.Fields(line); len(parts) == 2 {
			pcrMap[parts[0]] = parts[1]
		}
	}

	// Compare each PCR value with the baseline
	for pcrIndex, expectedValue := range PCRBaseline {
		if receivedValue, exists := pcrMap[pcrIndex]; !exists || receivedValue != expectedValue {
			return false, fmt.Sprintf("PCR %s mismatch: expected %s, got %s", pcrIndex, expectedValue, receivedValue)
		}
	}

	return true, "PCR values match baseline"
}

// VerifyQuote verifies the TPM quote using TPM2 tools
func VerifyQuote(req AttestationRequest) (bool, string) {
	// Save the received files to temporary files
	err := writeFile("quote_message.dat", req.Message)
	if err != nil {
		return false, "Failed to write quote message file"
	}
	err = writeFile("quote_signature.dat", req.Signature)
	if err != nil {
		return false, "Failed to write quote signature file"
	}
	err = writeFile("nonce.txt", req.Nonce)
	if err != nil {
		return false, "Failed to write nonce file"
	}
	err = writeFile("attestation_key.pub", req.PubKey)
	if err != nil {
		return false, "Failed to write public key file"
	}

	// Run TPM2 tools to verify the quote
	cmd := exec.Command("tpm2_checkquote", "--public", "attestation_key.pub", "--message", "quote_message.dat", "--signature", "quote_signature.dat", "--qualification", "nonce.txt")
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &out

	err = cmd.Run()
	if err != nil {
		log.Printf("Verification failed: %s\n", out.String())
		return false, out.String()
	}

	// Verify PCR values
	valid, message := VerifyPCRs(req.PCRValues)
	if !valid {
		return false, message
	}

	return true, "Verification successful"
}

// writeFile writes data to a file
func writeFile(filename, data string) error {
	return os.WriteFile(filename, []byte(data), 0644)
}

// attestationHandler handles the attestation request
func attestationHandler(w http.ResponseWriter, r *http.Request) {
	var req AttestationRequest
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	// Verify the quote
	valid, message := VerifyQuote(req)
	response := AttestationResponse{
		Status:  "FAIL",
		Message: message,
	}

	if valid {
		response.Status = "OK"
	}

	// Send response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func main() {
	// Load PCR baseline
	err := LoadPCRBaseline("pcr_values.json")
	if err != nil {
		log.Fatalf("Error loading PCR baseline: %v", err)
	}

	http.HandleFunc("/verify", attestationHandler)
	fmt.Println("Starting TPM attestation server on port 5000...")
	log.Fatal(http.ListenAndServe(":5000", nil))
}
