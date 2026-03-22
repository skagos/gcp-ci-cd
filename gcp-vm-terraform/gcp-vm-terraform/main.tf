provider "google" {
  project = "***"
  region  = "us-central1"
  zone    = "us-central1-a"
}

resource "google_compute_instance" "vm_instance" {
  name         = "docker-vm"
  machine_type = "e2-micro"  # Free tier eligible

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"

    access_config {
      # Assigns a public IP
    }
  }

  metadata = {
      ssh-keys = "***"
  }

  tags = ["http-server", "https-server"]
}
