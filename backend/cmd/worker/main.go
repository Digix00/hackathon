package main

import (
	"log"
	"os"
	"time"
)

func main() {
	interval := 30 * time.Second
	if os.Getenv("WORKER_ONESHOT") == "true" {
		log.Println("worker oneshot: boot ok")
		return
	}

	log.Printf("worker started: tick interval=%s", interval)
	for {
		log.Println("worker heartbeat")
		time.Sleep(interval)
	}
}
