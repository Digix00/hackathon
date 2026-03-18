package main

import (
	"log"
	"os"
	"time"
)

func main() {
	loc, err := time.LoadLocation("Asia/Tokyo")
	if err != nil {
		panic("time location load failed: " + err.Error())
	}
	time.Local = loc

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
