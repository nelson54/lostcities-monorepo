job "pgadmin" {
    region = "global"
    datacenters = [ "tower-datacenter"]
    type   = "service"

    constraint {
        attribute = "${node.unique.name}"
        value = "nomad-tower-red"
    }

    group "pgadmin" {
        count = 1



        network {
            mode = "bridge"

            port "service-port" {
                static=5050
                to=80
            }
        }

        service {
            name = "pgadmin"
            tags = ["pgadmin for boundary"]
            port = "service-port"
            #address_mode = "alloc"

            check {
                name     = "alive"
                type     = "tcp"
                interval = "10s"
                timeout  = "2s"
            }

            #check {
            #  type     = "script"
            #  name     = "pgadmin-health"
            #  command  = "/usr/local/bin/pg_isready"
            #  interval = "10s"
            #  timeout  = "5s"
            #  task = "pgadmin"
            #}
        }

        task "pgadmin" {

            driver = "podman"

            config {
                image = "docker.io/dpage/pgadmin4:latest"
                ports = ["service-port"]

                volumes = [
                    //"/shares/lostcities/pgadmin:/var/lib/pgadmin",

                ]

                logging {
          type = "journald"
          config {
            mode            = "non-blocking"
            max-buffer-size = "16m"
          }
        }
            }

            env {
                PGADMIN_DEFAULT_EMAIL="contact@dereknelson.io"
                PGADMIN_DEFAULT_PASSWORD="p@ssword"
                //POSTGRES_USER     = "root"
                //POSTGRES_PASSWORD = "rootpassword"
                //POSTGRES_DB       = "boundary"
                //PGDATA="/usr/local/pgsql/data"
            }

            logs {
                max_files     = 5
                max_file_size = 15
            }

            resources {
                cpu    = 500
                memory = 500
            }

            restart {
                attempts = 10
                interval = "30s"
                mode     = "fail"
                delay    = "25s"
            }

            template {
                data = <<EOH

EOH

                destination = "local/servers.json"
            }

        }

        update {
            max_parallel     = 1
            min_healthy_time = "20s"
            healthy_deadline = "3m"
            auto_revert      = true
            canary           = 1
            auto_promote     = true
        }
    }
}
