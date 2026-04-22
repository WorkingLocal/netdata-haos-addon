ARG BUILD_FROM=netdata/netdata:latest
FROM $BUILD_FROM

# Copy startup script
COPY rootfs/run.sh /run.sh
RUN chmod +x /run.sh

# Override entrypoint so we can configure before Netdata starts
ENTRYPOINT ["/run.sh"]
