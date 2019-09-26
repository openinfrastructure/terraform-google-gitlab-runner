# cloud-config
users:
  - name: gitlab-runner
    shell: /bin/bash
    uid: 2000
    groups:
      - docker

write_files:
  - path: /etc/gitlab-runner/config.toml
    owner: root:root
    permissions: '0644'
    content: |
      # Prometheus metrics at /metrics, also used for health checks.
      listen_address = ":${hc_port}"
  - path: /var/lib/cloud/bin/firewall
    permissions: 0755
    owner: root
    content: |
      #! /bin/bash
      iptables -w -A INPUT -p tcp --dport ${hc_port} -j ACCEPT
  - path: /etc/systemd/system/gitlab-runner.service
    permissions: 0644
    owner: root
    content: |
      [Unit]
      Description=GitLab Runner
      ConditionFileIsExecutable=/var/lib/google/bin/gitlab-runner
      After=syslog.target network-online.target
      [Service]
      StartLimitInterval=5
      StartLimitBurst=10
      ExecStart=/var/lib/google/bin/gitlab-runner "run" "--working-directory" "/home/gitlab-runner" "--config" "/etc/gitlab-runner/config.toml" "--service" "gitlab-runner" "--syslog" "--user" "gitlab-runner"
      Restart=always
      RestartSec=120
      [Install]
      WantedBy=multi-user.target
  - path: /etc/systemd/system/firewall.service
    permissions: 0644
    owner: root
    content: |
      [Unit]
      Description=Host firewall configuration
      ConditionFileIsExecutable=/var/lib/cloud/bin/firewall
      After=network-online.target
      [Service]
      ExecStart=/var/lib/cloud/bin/firewall
      Type=oneshot
      [Install]
      WantedBy=multi-user.target

runcmd:
  - mkdir /var/lib/google/tmp
  - mkdir /var/lib/google/bin
  - curl -L --output /var/lib/google/tmp/gitlab-runner ${gitlab-runner-url}
  - install -o 0 -g 0 -m 0755 /var/lib/google/tmp/gitlab-runner /var/lib/google/bin/gitlab-runner
  - /var/lib/google/bin/gitlab-runner register --non-interactive --url "${gitlab-url}" --registration-token "${registration_token}" --executor "docker" --docker-image alpine:latest --tag-list "${tag-list}" --run-untagged="true" --locked="false" --access-level="not_protected"
  - systemctl daemon-reload
  - systemctl start firewall.service
  - systemctl start gitlab-runner.service
