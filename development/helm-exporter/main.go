package main

import (
	"context"
	"fmt"
	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"helm.sh/helm/v3/pkg/action"
	"helm.sh/helm/v3/pkg/cli"
	_ "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"

	// Necessary for kubeconfig and in-cluster authentication
	_ "k8s.io/client-go/plugin/pkg/client/auth"
)

// Initialize Prometheus metric
var (
	releaseInfo = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "helm_release_info",
			Help: "Information about Helm releases in the cluster",
		},
		[]string{"name", "namespace", "version", "status", "lastDeployed"},
	)
)

func init() {
	prometheus.MustRegister(releaseInfo)
}

// Fetch all namespaces
func getAllNamespaces() ([]string, error) {
	var config *rest.Config
	var err error

	if kubeconfig := os.Getenv("KUBECONFIG"); kubeconfig != "" {
		config, err = clientcmd.BuildConfigFromFlags("", kubeconfig)
	} else {
		config, err = rest.InClusterConfig()
	}
	if err != nil {
		return nil, fmt.Errorf("error getting k8s config: %w", err)
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		return nil, fmt.Errorf("error getting k8s client set: %w", err)
	}

	namespaces, err := clientset.CoreV1().Namespaces().List(context.TODO(), v1.ListOptions{})
	if err != nil {
		return nil, fmt.Errorf("error listing namespaces: %w", err)
	}

	var namespaceList []string
	for _, namespace := range namespaces.Items {
		namespaceList = append(namespaceList, namespace.Name)
	}

	return namespaceList, nil
}

func recordMetrics(settings *cli.EnvSettings) {
	namespaces, err := getAllNamespaces()
	if err != nil {
		panic(err)
	}

	for _, ns := range namespaces {
		actionConfig := new(action.Configuration)
		// Initialize with the current namespace
		if err := actionConfig.Init(settings.RESTClientGetter(), ns, os.Getenv("HELM_DRIVER"), func(format string, v ...interface{}) {}); err != nil {
			fmt.Printf("Error initializing action configuration: %v\n", err)
			continue
		}

		client := action.NewList(actionConfig)
		client.All = true
		client.Deployed = true

		releases, err := client.Run()
		if err != nil {
			fmt.Printf("Error listing releases in namespace '%s': %v\n", ns, err)
			continue
		}

		for _, rel := range releases {
			releaseInfo.With(prometheus.Labels{"name": rel.Name, "namespace": ns, "version": rel.Chart.Metadata.Version, "status": rel.Info.Status.String(), "lastDeployed": rel.Info.LastDeployed.String()}).Set(1)
		}
	}
}

// Logging middleware for HTTP handlers
func logRequest(handler http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Printf("Received request for %s", r.URL.Path)
		handler.ServeHTTP(w, r) // Forward the request to the actual handler
	})
}
func main() {
	settings := cli.New()

	http.Handle("/metrics", logRequest(promhttp.Handler()))
	go func() {
		for {
			recordMetrics(settings)
			// Update metrics every 60 seconds
			time.Sleep(60 * time.Second)
		}
	}()

	http.ListenAndServe(":8080", nil)
}
