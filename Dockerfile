FROM ruby

COPY Gemfile transmission_chaos.gemspec /app/
COPY bin/ /app/bin/
COPY lib/ /app/lib/
WORKDIR /app

RUN bundle install -j4 \
 && echo "#!/bin/sh\ncd /app\nexec bundle exec bin/transmission_chaos \"\$@\"" > /usr/local/bin/transmission_chaos \
 && chmod +x /usr/local/bin/transmission_chaos

ENTRYPOINT [ "/usr/local/bin/transmission_chaos" ]
