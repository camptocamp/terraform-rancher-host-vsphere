#cloud-config

packages:
  - puppet-agent

write_files:
  - path: "/etc/puppetlabs/puppet/csr_attributes.yaml"
    content: |
      custom_attributes:
        1.2.840.113549.1.9.7: "${puppet_autosign_challenge}"
      extension_requests:
        pp_role: "${puppet_role}"
        pp_environment: "${puppet_environment}"
  - path: "/etc/puppetlabs/puppet/puppet.conf"
    content: |
      [agent]
      server = ${puppet_server}
      ca_server = ${puppet_caserver}
      certificate_revocation = false
      environment = ${puppet_environment}
      http_read_timeout = 120
      show_diff = true
      splay = true
      usecacheonfailure = false

runcmd:
  - [ "/opt/puppetlabs/bin/puppet", "agent", "-t", "--environment", "production" ]
  - [ "sh", "-c", "/opt/puppetlabs/bin/puppet agent -t | tee /dev/null" ] # Ugly hack for CentOS
  - [ "rm", "-f", "/etc/puppetlabs/puppet/csr_attributes.yaml" ]
