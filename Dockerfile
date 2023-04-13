FROM ruby:alpine

WORKDIR /app
COPY Gemfile *.gemspec /app/
COPY bin /app/bin/
COPY lib /app/lib/

RUN bundle config set --local path 'vendor' \
 && bundle config set --local without 'development' \
 && bundle install

ENTRYPOINT [ "/usr/local/bin/bundle", "exec", "bin/transmission_chaos" ]
