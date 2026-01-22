variable "email" {
  type = string
  default = "contact@dereknelson.io"
}


job "nginx" {
  datacenters = ["tower-datacenter"]
  #namespace = "default"

  spread {
    attribute =  "${node.unique.name}"
    weight    = 100
  }

  update {
    stagger      = "30s"
    max_parallel = 1
  }

  group "work" {
    # My cluster node names are cluster-0, cluster-1, etc.
    # I run this job on a single node at a time, and "pin" it to the same node using the below constraint
    # This way, once certificates are generated for my domains, they'll be reused until they expire since
    # the job always runs on the same host where they were generated.
    count = 1
    constraint {
      attribute = "${node.unique.name}"
      operator = "set_contains_any"

      # CHANGE THIS TO THE NAME OF THE NODE THAT WILL RUN NGINX
      value    = "nomad-tower-red"
    }

    network {
      port "http" {
        to = 3000
      }
      port "https" {
        static = 443
      }
    }

   # This is the task that fetches certificates for all of our domains and places them on our host volume
   # Doing so makes the certificates available in our `nginx` job
   # Note: This task's lifecycle is "prestart", meaning it must complete before the `nginx` task starts
   task "certbot-all-domains" {
      driver = "podman"
      user = "root"

      config {
        image = "docker.io/certbot/certbot"
        # We use a custom entrypoint so we can script this tasks's behavior
        volumes = [
          # Make our load-balancer.conf available in nginx's config directory
          "local/conf:/etc/nginx/conf.d",
          "local/conf:/etc/nginx/ssl",
          "local/conf:/var/www/certbot"
        ]
        entrypoint = ["${NOMAD_TASK_DIR}/run.sh"]
      }

      template {
        data = <<EOF

EOF
        destination   = "local/conf/test.txt"
      }

      template {
        data = <<EOF
#!/bin/sh

# Note, we're not dealing with bash here. We're dealing with 'ash', as this docker image is BusyBox linux
# Hence, we can't use normal bash arrays. Separate each domain by SPACES, NOTE COMMAS
DOMAINS="lostcities.dev www.lostcities.dev"

# Set this to an empty string "" for production mode
#STAGING="--staging"
STAGING=""
DNS_PROPAGATION_SECONDS=30

set -- $DOMAINS

while [ -n "$1" ]; do
  domain=$1
  echo "Domain: $domain"

  certbot certonly -v $STAGING --cert-name ${domain} -d ${domain} -d *.${domain} --agree-tos -m ${var.email} --keep-until-expiring

  echo "Done with: $domain"
  shift
done
EOF

        destination   = "${NOMAD_TASK_DIR}/run.sh"
        perms = "755"
      }

      resources {
        cpu = 50
        memory = 100
      }

      lifecycle {
        hook    = "prestart"
        sidecar = false
      }
    }
  }
}
