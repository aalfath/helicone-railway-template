# Helicone Jawn (API server and LLM proxy), official image pinned by version and digest.
FROM helicone/jawn:v2025.08.21@sha256:0becc2fffc3a35096ca815dd83e1819c42593d6def7f335521268321ad21c776

COPY start.sh /railway/start.sh
RUN chmod 0755 /railway/start.sh

CMD ["/railway/start.sh"]
