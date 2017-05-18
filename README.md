# Disposable Ansible playground

Neutral Debian-based Docker image running an OpenSSH server with [s6](https://github.com/skarnet/s6). Designed for
executing Ansible playbooks in reproducible environments using SSH and [non-SSH][nonssh] connection types.

Containers are ideal for running Ansible integration tests because they allow the creation of disposable environments
locally without any resource overhead.

[nonssh]: http://docs.ansible.com/ansible/intro_inventory.html#non-ssh-connection-types

## Building the image

The `USER_SSH_PUBKEY` variable **must** be passed as a build-time variable to Docker:

```sh
❯ docker build \
     -t demo/debian-ssh \
     --build-arg USER_SSH_PUBKEY="$(cat ~/.ssh/id_ecdsa.pub)" .
```

The resulting image starts an `sshd` instance listening on port 22.

## Connecting via SSH

Create a container from that image and connect to the running container via SSH with the `ansible` user, using the SSH
key corresponding to the `USER_SSH_PUBKEY` variable set at build time:

**Linux**

The IP address of the container is directly accessible from the local host.

```sh
❯ CONTAINER_ID="$(docker run -d demo/debian-ssh)" # eg. df626f91b277
❯ CONTAINER_IPADDR="$(docker container inspect \
    --format '{{ .NetworkSettings.IPAddress }}' "$CONTAINER_ID")" # eg. 172.17.0.2

❯ ssh ansible@"$CONTAINER_IPADDR"
```

**macOS**

The IP address of the container is not directly accessible from the local host. One must publish the port 22 of the
container to some port on the local host.

```sh
❯ CONTAINER_ID="$(docker -d -p 22 run demo/debian-ssh)"  # eg. df626f91b277
❯ CONTAINER_PORT="$(docker container inspect \
    --format '{{ index .NetworkSettings.Ports "22/tcp" 0 "HostPort" }}' "$CONTAINER_ID")" # eg. 32770

❯ ssh ansible@localhost -p"$CONTAINER_PORT"
```

### Integration with an Ansible inventory

Add the local container(s) to your Ansible inventory:

```ini
# /etc/ansible/hosts

[localdocker]
# linux
docker1 ansible_host=172.17.0.2
docker2 ansible_host=172.17.0.3
# macos
# docker1 ansible_host=localhost ansible_port=32770
# docker2 ansible_host=localhost ansible_port=32771

[localdocker:vars]
ansible_user=ansible
```

```sh
❯ ansible -a 'cat /etc/os-release' localdocker
docker1 | SUCCESS | rc=0 >>
PRETTY_NAME="Debian GNU/Linux 8 (jessie)"
NAME="Debian GNU/Linux"
[...]
```
