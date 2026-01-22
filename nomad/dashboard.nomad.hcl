variable "priority" {
  type = number
  default = 60
}

job "homepage"  {
  datacenters = [ "tower-datacenter"]
  type = "service"
  priority = var.priority

  group "homepage" {
    network {
      port "port_http" {
        to     = 8080
      }
    }

    restart {
      interval = "10m"
      attempts = 20
      delay    = "30s"
    }

    service {
      name = "homepage"
      port = "port_http"
      tags = [
        "urlprefix-dashboard.lostcities.app"
        //"traefik.enable=true"
      ]

      check {
        type = "http"
        port = "port_http"
        path = "/"
        interval = "30s"
        timeout = "5s"
      }
    }

    task "homepage" {
      driver = "podman"

      config {
        image = "docker.io/b4bz/homer:latest"
        //hostname = "homepage"

        ports = ["port_http"]

        args  = [
        ]

        volumes = [
          "local/config.yml:/www/assets/config.yml"
        ]

        //logging  {
        //  type = "loki"
        //  config {
        //    loki-url = "http://192.168.1.233:3100/loki/api/v1/push"
        //    loki-external-labels = "job=${NOMAD_JOB_ID},task=${NOMAD_TASK_NAME}"
        //  }
        //}

      }

      resources {
        cpu = 100
        memory = 100
      }

      template {
        data = <<EOF
---
# Homepage configuration
# See https://fontawesome.com/v5/search for icons options

# Optional: Use external configuration file.
# Using this will ignore remaining config in this file
# externalConfig: https://example.com/server-luci/config.yaml

title: "Tower Cluster"
subtitle: "Nomad"
# documentTitle: "Welcome" # Customize the browser tab text
#logo: "assets/logo.png"
# Alternatively a fa icon can be provided:
icon: "fas fa-skull-crossbones"

header: true # Set to false to hide the header
# Optional: Different hotkey for search, defaults to "/"
# hotkey:
#   search: "Shift"
footer: '<p>Created with <span class="has-text-danger">❤️</span> with <a href="https://bulma.io/">bulma</a>, <a href="https://vuejs.org/">vuejs</a> & <a href="https://fontawesome.com/">font awesome</a> // Fork me on <a href="https://github.com/bastienwirtz/homer"><i class="fab fa-github-alt"></i></a></p>' # set false if you want to hide it.

columns: "3" # "auto" or number (must be a factor of 12: 1, 2, 3, 4, 6, 12)
connectivityCheck: true # whether you want to display a message when the apps are not accessible anymore (VPN disconnected for example).
                        # You should set it to true when using an authentication proxy, it also reloads the page when a redirection is detected when checking connectivity.

# Optional: Proxy / hosting option
proxy:
  useCredentials: false # send cookies & authorization headers when fetching service specific data. Set to `true` if you use an authentication proxy. Can be overrided on service level.
  headers: # send custom headers when fetching service specific data. Can also be set on a service level.
    Test: "Example"
    Test1: "Example1"


# Set the default layout and color scheme
defaults:
  layout: columns # Either 'columns', or 'list'
  colorTheme: auto # One of 'auto', 'light', or 'dark'

# Optional theming
theme: default # 'default' or one of the themes available in 'src/assets/themes'.

# Optional custom stylesheet
# Will load custom CSS files. Especially useful for custom icon sets.
# stylesheet:
#   - "assets/custom.css"

# Here is the exhaustive list of customization parameters
# However all value are optional and will fallback to default if not set.
# if you want to change only some of the colors, feel free to remove all unused key.
#colors:
#  light:
#    highlight-primary: "#3367d6"
#    highlight-secondary: "#4285f4"
#    highlight-hover: "#5a95f5"
#    background: "#f5f5f5"
#    card-background: "#ffffff"
#    text: "#363636"
#    text-header: "#424242"
#    text-title: "#303030"
#    text-subtitle: "#424242"
#    card-shadow: rgba(0, 0, 0, 0.1)
#    link: "#3273dc"
#    link-hover: "#363636"
#    background-image: "assets/your/light/bg.png"
#  dark:
#    highlight-primary: "#3367d6"
#    highlight-secondary: "#4285f4"
#    highlight-hover: "#5a95f5"
#    background: "#131313"
#    card-background: "#2b2b2b"
#    text: "#eaeaea"
#    text-header: "#ffffff"
#    text-title: "#fafafa"
#    text-subtitle: "#f5f5f5"
#    card-shadow: rgba(0, 0, 0, 0.4)
#    link: "#3273dc"
#    link-hover: "#ffdd57"
#    background-image: "assets/your/dark/bg.png"

# Optional message
message:
  # url: "https://<my-api-endpoint>" # Can fetch information from an endpoint to override value below.
  # mapping: # allows to map fields from the remote format to the one expected by Homer
  #   title: 'id' # use value from field 'id' as title
  #   content: 'value' # value from field 'value' as content
  # refreshInterval: 10000 # Optional: time interval to refresh message
  #
  # Real example using chucknorris.io for showing Chuck Norris facts as messages:
  # url: https://api.chucknorris.io/jokes/random
  # mapping:
  #   title: 'id'
  #   content: 'value'
  # refreshInterval: 10000
  style: "is-warning"
  title: "Optional message!"
  icon: "fa fa-exclamation-triangle"
  # The content also accepts HTML content, so you can add divs, images or whatever you want to make match your needs.
  content: "Lorem ipsum dolor sit amet, consectetur adipiscing elit."

# Optional navbar
# links: [] # Allows for navbar (dark mode, layout, and search) without any links
links:
  - name: "Link 1"
    icon: "fab fa-github"
    url: "https://github.com/bastienwirtz/homer"
    target: "_blank" # optional html tag target attribute
  - name: "link 2"
    icon: "fas fa-book"
    url: "https://github.com/bastienwirtz/homer"
  # this will link to a second homer page that will load config from page2.yml and keep default config values as in config.yml file
  # see url field and assets/page.yml used in this example:
  - name: "Second Page"
    icon: "fas fa-file-alt"
    url: "#page2"

# Services
# First level array represents a group.
# Leave only a "items" key if not using group (group name, icon & tagstyle are optional, section separation will not be displayed).
services:
  - name: "Nomad"
    icon: "fas fa-code-branch"
    # A path to an image can also be provided. Note that icon take precedence if both icon and logo are set.
    # logo: "path/to/logo"
    # class: "highlight-purple" # Optional css class to add on the service group.
    items:
      - name: "Nomad Blue"
        logo: "https://www.lostcities.app/img/nomad.png"
        subtitle: "Nomad"
        tag: "app"
        keywords: "self hosted reddit"
        url: "https://nomad-blue.lostcities.app"
        target: "_blank"
      - name: "Nomad Blue"
        logo: "https://www.lostcities.app/img/nomad.png"
        subtitle: "Nomad"
        tag: "app"
        keywords: "self hosted reddit"
        url: "https://nomad-blue.lostcities.app"
        target: "_blank"
      - name: "Nomad Blue"
        logo: "https://www.lostcities.app/img/nomad.png"
        subtitle: "Nomad"
        tag: "app"
        keywords: "self hosted reddit"
        url: "https://nomad-blue.lostcities.app"
        target: "_blank"
  - name: "Consul"
    icon: "fas fa-heartbeat"
    items:
      - name: "Consul Blue"
        logo: "https://www.lostcities.app/img/consul.png"
        subtitle: "Consul"
        tag: "app"
        keywords: "self hosted reddit"
        url: "https://consul-blue.lostcities.app"
        target: "_blank"
      - name: "Consul Green"
        logo: "https://www.lostcities.app/img/consul.png"
        subtitle: "Consul"
        tag: "app"
        keywords: "self hosted reddit"
        url: "https://consul-blue.lostcities.app"
        target: "_blank"
      - name: "Consul Red"
        logo: "https://www.lostcities.app/img/consul.png"
        subtitle: "Consul"
        tag: "app"
        keywords: "self hosted reddit"
        url: "https://consul-blue.lostcities.app"
        target: "_blank"
  - name: "Monitoring"
    icon: "fab fa-chart-line"
    # A path to an image can also be provided. Note that icon take precedence if both icon and logo are set.
    # logo: "path/to/logo"
    # class: "highlight-purple" # Optional css class to add on the service group.
    items:
      - name: "Grafana"
        logo: "https://www.lostcities.app/img/grafana.png"
        subtitle: "Grafana"
        tag: "app"
        keywords: "self hosted reddit"
        url: "https://grafana.lostcities.app"
        target: "_blank"
      - name: "Prometheus Agent"
        # type: Prometheus
        logo: "https://www.lostcities.app/img/prometheus.png"
        subtitle: "Prometheus"
        tag: "app"
        keywords: "self hosted reddit"
        url: "https://prometheus-agent.lostcities.app"
        target: "_blank"
      - name: "Prometheus Query"
        # type: Prometheus
        logo: "https://www.lostcities.app/img/prometheus.png"
        subtitle: "Prometheus"
        tag: "app"
        keywords: "self hosted reddit"
        url: "https://prometheus.lostcities.app"
        target: "_blank"
      - name: "Uptime Kuma"
        logo: "https://www.lostcities.app/img/uptime.png"
        # subtitle: "A fancy self-hosted monitoring tool" # optional, if no subtitle is defined, Uptime Kuma incidents, if any, will be shown
        url: "https://uptime.lostcities.app"
        # type: "UptimeKuma"
  - name: "Infrastructure"
    # A path to an image can also be provided. Note that icon take precedence if both icon and logo are set.
    # logo: "path/to/logo"
    # class: "highlight-purple" # Optional css class to add on the service group.
    items:
      - name: "RabbitMq"
        logo: "https://www.lostcities.app/img/rabbitmq.png"
        subtitle: "Grafana"
        tag: "app"
        keywords: "self hosted reddit"
        url: "https://rabbitmq.lostcities.app"
        target: "_blank"
      - name: "Fabio"
        logo: "https://www.lostcities.app/img/fabio.png"
        subtitle: "Fabio"
        tag: "app"
        keywords: "self hosted reddit"
        url: "https://fabiolb.lostcities.app"
        target: "_blank"
  - name: "Lostcities"
    icon: "fas fa-code-branch"
    # A path to an image can also be provided. Note that icon take precedence if both icon and logo are set.
    # logo: "path/to/logo"
    # class: "highlight-purple" # Optional css class to add on the service group.
    items:
      - name: "Homepage"
        logo: "https://www.lostcities.app/img/lostcities.png"
        subtitle: "Grafana"
        tag: "app"
        keywords: "self hosted reddit"
        url: "https://www.lostcities.app"
        target: "_blank"

  - name: "Github"
    icon: "fas fa-code-branch"
    # A path to an image can also be provided. Note that icon take precedence if both icon and logo are set.
    # logo: "path/to/logo"
    # class: "highlight-purple" # Optional css class to add on the service group.
    items:
      - name: "Composite"
        icon: "fab fa-github"
        subtitle: "Grafana"
        tag: "github"
        keywords: "github"
        url: "https://github.com/lostcities-cloud/lostcities-composite"
        target: "_blank"

      - name: "Frontend"
        icon: "fab fa-github"
        subtitle: "Grafana"
        tag: "github"
        keywords: "github"
        url: "https://github.com/lostcities-cloud/lostcities-frontend"
        target: "_blank"

      - name: "Accounts"

        icon: "fab fa-github"
        subtitle: "Grafana"
        tag: "app"
        keywords: "github"
        url: "https://github.com/lostcities-cloud/lostcities-accounts"
        target: "_blank"
      - name: "Gamestate"

        icon: "fab fa-github"
        subtitle: "Grafana"
        tag: "github"
        keywords: "github"
        url: "https://github.com/lostcities-cloud/lostcities-gamestate"
        target: "_blank"
      - name: "Matches"

        icon: "fab fa-github"
        subtitle: "Grafana"
        tag: "github"
        keywords: "github"
        url: "https://github.com/lostcities-cloud/lostcities-matches"
        target: "_blank"
      - name: "Player Events"

        icon: "fab fa-github"
        subtitle: "Grafana"
        tag: "github"
        keywords: "github"
        url: "https://github.com/lostcities-cloud/lostcities-player-events"
        target: "_blank"

EOF

        destination   = "local/config.yml"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }
  }
}
