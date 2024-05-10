locals {
  zone = "${var.region_name}-b"
}

resource "google_compute_network" "vpc_network" {
  project                 = "tf-alhartdj"
  name                    = "vpc-network"
  auto_create_subnetworks = false
}
resource "google_compute_subnetwork" "subnet_network" {
  name          = "my-subnetwork"
  ip_cidr_range = "192.168.0.0/24"
  region        = "${var.region_name}"
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_instance" "vm_dan" {
  for_each = var.instance_types
  #count = var.chk ? 1 : 0 
  name         = "${var.prefix}-${each.key}"
  machine_type = each.value[0]
  description = each.value[1]
  zone         = local.zone
  tags = ["www"]
  
network_interface {
    network = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet_network.id
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

    metadata_startup_script = "apt update && apt install -y nginx"

  }

  resource "google_compute_firewall" "allow_www_fw" {
  name    = "www-firewall"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges = ["192.168.0.0/24"]
  target_tags = ["www"]
}

  resource "google_compute_firewall" "allow_iap_fw" {
  name    = "iap-firewall"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
}

 resource "google_compute_instance_group" "unmanaged" {
  name = "unmanaged-list"
  description = "unmanaged group"
  zone = local.zone
  instances = [for _,v in google_compute_instance.vm_dan : v.id]
  named_port {
    name = "http"
    port = "80"
  }

}

####################################################################

module "ilb" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-lb-int?ref=v25.0.0"
  project_id    = "tf-alhartdj"
  region        = "me-central2"
  name          = "ilb-test"
  service_label = "ilb-test"
  vpc_config = {
    network    = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.subnet_network.self_link
  }
  backends = [{
    group = google_compute_instance_group.unmanaged.id
  }]
  health_check_config = {
    http = {
      port = 80
    }
  }
}

module "nat" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-cloudnat?ref=v25.0.0"
  project_id     = "tf-alhartdj"
  region         = "me-central2"
  name           = "send-to-e"
  router_network = google_compute_network.vpc_network.id
}

resource "google_compute_firewall" "allow_health_chk" {
  name    = "health-firewall"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
}

resource "google_compute_instance" "dan_client" {
  name         = "dan-client"
  machine_type = "e2-micro"
  zone         = local.zone
  
network_interface {
    network = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet_network.id
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
}

resource "google_storage_bucket" "state_gcs" {
  name          = "tf-alhartdj-gcs"
  location      = "me-central2"
  force_destroy = true
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}
