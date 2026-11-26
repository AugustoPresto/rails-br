ARG RUBY_VERSION=3.4
FROM ruby:${RUBY_VERSION}

ARG RAILS_VERSION=8.0
ARG RAILS_BR_VERSION=0.2.1
ENV RAILS_VERSION=${RAILS_VERSION} RAILS_BR_VERSION=${RAILS_BR_VERSION}

COPY setup.sh /setup.sh
RUN bash /setup.sh

# Os mesmos models, controllers, migrações e testes em todas as combinações.
COPY overlay/ /app/
WORKDIR /app
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["bash", "/entrypoint.sh"]
