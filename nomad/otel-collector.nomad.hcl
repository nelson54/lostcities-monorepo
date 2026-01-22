# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# Nomad adaption of the Kubernetes example from
# https://github.com/open-telemetry/opentelemetry-collector/blob/main/examples/k8s/otel-config.yaml

variables {
  otel_image = "docker.io/otel/opentelemetry-collector-contrib:0.109.0"
}

job "otel-collector" {
  datacenters = ["tower-datacenter"]
  namespace = "lostcities"
  type        = "service"

  group "otel-collector" {
    count = 1

    network {
      port "metrics" {
        to = 8888
      }

      port "http" {
        to = 4318
      }

      # Receivers
      port "grpc" {
        to = 4317
      }

      port "jaeger-grpc" {
        to = 14250
      }

      port "jaeger-thrift-http" {
        to = 14268
      }

      port "zipkin" {
        to = 9411
      }

      # Extensions
      port "zpages" {
        to = 55679
      }
    }

    service {
      name     = "otel-collector"
      port     = "grpc"
      tags     = ["grpc"]
      provider = "nomad"
    }

    task "otel-collector" {
      driver = "podman"

      config {
        image = var.otel_image

        args = [
          "--config=local/config/otel-collector-config.yaml",
        ]

        ports = [
          "metrics",
          "http",
          "grpc",
          "jaeger-grpc",
          "jaeger-thrift-http",
          "zipkin",
          "zpages",
        ]
      }

      resources {
        cpu    = 500
        memory = 2048
      }

      template {
        data = <<EOF



receivers:
  otlp:
    protocols:
      http:
        endpoint: '0.0.0.0:4318'
{{ range service "postgres" }}
  postgresql:
    endpoint: '{{ .Address }}:{{ .Port }}'
    transport: tcp
    username: otel
    password: example
    databases:
      - lostcities-accounts
      - lostcities-matches
    collection_interval: 15s

    tls:
      insecure: true
      insecure_skip_verify: true
{{ else }}
  postgresql:
    endpoint: 'localhost:5432'
    transport: tcp
    username: otel
    password: example
    databases:
      - lostcities-accounts
      - lostcities-matches
    collection_interval: 15s

    tls:
      insecure: true
      insecure_skip_verify: true
{{ end }}

exporters:
{{ range service "prometheus-query" }}
  prometheusremotewrite:
    endpoint: 'http://{{ .Address }}:{{ .Port }}/api/v1/write'
    send_metadata: true
    resource_to_telemetry_conversion:
      enabled: true
    target_info:
      enabled: true
    export_created_metric:
      enabled: true
{{ else }}
  prometheusremotewrite:
    endpoint: 'http://localhost:1234/api/v1/write'
    send_metadata: true
    resource_to_telemetry_conversion:
      enabled: true
    target_info:
      enabled: true
    export_created_metric:
      enabled: true
{{ end }}
  debug:
    verbosity: detailed
service:
  pipelines:
    metrics:
      receivers: [otlp, postgresql]

      exporters: [prometheusremotewrite]
    traces:
      receivers: [otlp]
      exporters: [debug]
    logs:
      receivers: [otlp]
      exporters: [debug]
EOF

        destination = "local/config/otel-collector-config.yaml"
      }
    }
  }
}
