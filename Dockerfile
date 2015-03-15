FROM quay.io/sorah/rbenv:2.2
MAINTAINER her@sorah.jp

ADD Gemfile* /app/
ADD *.rb /app/

ENV BUNDLE_GEMFILE /app/Gemfile

RUN bundle install --jobs 4 --path /app/vendor/bundle --deployment --without development:test

CMD /usr/bin/ruby /app/conoha-monitor.rb
