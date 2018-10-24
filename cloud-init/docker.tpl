#cloud-config

packages:
  - docker-ce

write_files:
  - path: "/etc/docker/daemon.json"
    content: |
      {
        "live-restore": true,
        "log-driver": "journald",
        "log-opts": {
          "tag": "###IMAGE:{{.ImageName}}###LABELS:{{.ContainerLabels}}###"
        },
        "mtu": 1440,
        "storage-driver": "overlay2",
        "storage-opts": [
          "overlay2.override_kernel_check=true"
        ]
      }

runcmd:
  - [ systemctl, daemon-reload ]
  - [ systemctl, enable, docker.service ]
  - [ systemctl, start, --no-block, docker.service ]
  - [ sleep, 1 ]
