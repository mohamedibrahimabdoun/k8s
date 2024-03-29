package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/braintree/manners"
	"github.com/GoogleCloudPlatform/kubernetes-workshops/bundles/kubernetes-101/workshop/app/handlers"
	"github.com/GoogleCloudPlatform/kubernetes-workshops/bundles/kubernetes-101/workshop/app/health"
	"github.com/GoogleCloudPlatform/kubernetes-workshops/bundles/kubernetes-101/workshop/app/user"
)

const version = "1.0.0"

func main() {
	var (
		httpAddr   = flag.String("http", "0.0.0.0:80", "HTTP service address.")
		healthAddr = flag.String("health", "0.0.0.0:81", "Health service address.")
		secret     = flag.String("secret", "secret", "JWT signing secret.")
	)
	flag.Parse()

	log.Println("Starting Auth service...")
	log.Printf("Health service listening on %s", *healthAddr)
	log.Printf("HTTP service listening on %s", *httpAddr)

	errChan := make(chan error, 10)

	hmux := http.NewServeMux()
	hmux.HandleFunc("/healthz", health.HealthzHandler)
	hmux.HandleFunc("/readiness", health.ReadinessHandler)
	hmux.HandleFunc("/healthz/status", health.HealthzStatusHandler)
	hmux.HandleFunc("/readiness/status", health.ReadinessStatusHandler)
	healthServer := manners.NewServer()
	healthServer.Addr = *healthAddr
	healthServer.Handler = handlers.LoggingHandler(hmux)

	go func() {
		errChan <- healthServer.ListenAndServe()
	}()

	mux := http.NewServeMux()
	mux.Handle("/login", handlers.LoginHandler(*secret, user.DB))
	mux.Handle("/version", handlers.VersionHandler(version))

	httpServer := manners.NewServer()
	httpServer.Addr = *httpAddr
	httpServer.Handler = handlers.LoggingHandler(mux)

	go func() {
		errChan <- httpServer.ListenAndServe()
	}()

	signalChan := make(chan os.Signal, 1)
	signal.Notify(signalChan, syscall.SIGINT, syscall.SIGTERM)

	for {
		select {
		case err := <-errChan:
			if err != nil {
				log.Fatal(err)
			}
		case s := <-signalChan:
			log.Println(fmt.Sprintf("Captured %v. Exiting...", s))
			health.SetReadinessStatus(http.StatusServiceUnavailable)
			httpServer.BlockingClose()
			os.Exit(0)
		}
	}
}
