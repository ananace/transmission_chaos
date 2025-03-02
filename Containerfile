FROM ghcr.io/linuxcontainers/alpine

WORKDIR /app
COPY Gemfile *.gemspec /app/
COPY bin /app/bin/
COPY lib /app/lib/

RUN apk add --no-cache ruby ruby-bundler \
 && gem install -N logging \
 && bundle config set --local path 'vendor' \
 && bundle config set --local without 'development' \
 && bundle install

ENTRYPOINT [ "/usr/bin/bundle", "exec", "bin/transmission_chaos" ]
