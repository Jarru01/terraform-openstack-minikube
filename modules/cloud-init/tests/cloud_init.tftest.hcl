# The cloudinit provider renders locally, so these tests need no cloud.

run "minikube_by_default" {
  command = plan

  assert {
    condition     = output.part_names == ["10-base.sh", "20-docker.sh", "30-minikube.sh"]
    error_message = "Default user data should contain base, docker and minikube parts, in that order."
  }

  assert {
    condition     = strcontains(output.user_data, "--nodes=3") && strcontains(output.user_data, "KUBERNETES_VERSION=\"v1.37.0\"")
    error_message = "The minikube part should carry the node count and the pinned Kubernetes version."
  }
}

run "docker_only" {
  command = plan

  variables {
    install_minikube = false
  }

  assert {
    condition     = output.part_names == ["10-base.sh", "20-docker.sh"]
    error_message = "install_minikube = false should leave out the minikube part."
  }

  assert {
    condition     = !strcontains(output.user_data, "minikube")
    error_message = "Docker-only user data must not mention minikube."
  }
}

run "custom_user_and_shape" {
  command = plan

  variables {
    ssh_user           = "debian"
    node_count         = 2
    memory_per_node_mb = 4096
  }

  assert {
    condition     = strcontains(output.user_data, "usermod -aG docker \"debian\"") && strcontains(output.user_data, "--nodes=2") && strcontains(output.user_data, "--memory=4096mb")
    error_message = "Variables should be rendered into the scripts."
  }
}

run "rejects_single_cpu_nodes" {
  command = plan

  variables {
    cpus_per_node = 1
  }

  expect_failures = [var.cpus_per_node]
}

run "rejects_bad_version" {
  command = plan

  variables {
    kubernetes_version = "1.37"
  }

  expect_failures = [var.kubernetes_version]
}
