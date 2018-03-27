#cloud-config

yum_repos:
  c2c-docker:
    name: Camptocamp-$releasever - Docker
    baseurl: http://pkg.camptocamp.net/yum/docker/$releasever/$basearch/
    gpgcheck: 0
  c2c-puppetlabs:
    name: Camptocamp-$releasever - Puppetlabs
    baseurl: http://pkg.camptocamp.net/yum/puppetlabs/$releasever/$basearch/
    gpgcheck: 0

# TODO: improve this when using cloud-init v0.7.8
apt_sources:
  - source: "deb http://pkg.camptocamp.net/apt $RELEASE/staging sysadmin docker"
    key: |
      -----BEGIN PGP PUBLIC KEY BLOCK-----
      Version: GnuPG v1.4.10 (GNU/Linux)

      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
      I5Mu42OXJoj/ux+cR9WUdzv6NvuqJd7m
      =FHxA
      -----END PGP PUBLIC KEY BLOCK-----

package_upgrade: true

packages:
  - lvm2

power_state:
  mode: reboot
  message: Bye Bye
  timeout: 30
  condition: True
