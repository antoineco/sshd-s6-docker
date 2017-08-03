FROM debian:8

ENTRYPOINT ["/init"]

ENV S6_OVERLAY_VERSION 1.19.1.1

# install required packages
RUN runDeps=" \
		openssh-server \
		sudo \
		ca-certificates \
		curl \
		python \
	" \
	# install dependencies
	&& apt-get update \
	&& apt-get install -y --no-install-recommends $runDeps \
	&& rm -r /var/lib/apt/lists/*

# install s6-overlay
RUN set -x \
	# fetch s6-overlay archive and signature
	&& curl -sSLo s6.tgz \
		https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-amd64.tar.gz \
	&& curl -sSLo s6.sig \
		https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-amd64.tar.gz.sig \
	# gpg verification
	&& export GNUPGHOME="$(mktemp -d)" \
	&& curl -sSL https://keybase.io/justcontainers/key.asc | gpg --import \
	&& gpg --batch --verify s6.sig s6.tgz \
	# extract s6-overlay archive
	&& tar -xzf s6.tgz -C / \
	# cleanup
	&& rm -r "$GNUPGHOME" s6.sig s6.tgz

COPY services.d/ /etc/services.d/

# add test user
ARG USER_SSH_PUBKEY
RUN \
	adduser ansible --disabled-password --gecos Ansible \
	&& ( \
		umask 077 \
		&& mkdir ~ansible/.ssh \
		&& echo "${USER_SSH_PUBKEY}" \
			> ~ansible/.ssh/authorized_keys \
	) \
	&& chown -R ansible:ansible ~ansible/.ssh \
	&& ( \
		umask 227 \
		&& echo -e "ansible\tALL=(ALL:ALL) NOPASSWD: ALL" \
			> /etc/sudoers.d/ansible \
	)
