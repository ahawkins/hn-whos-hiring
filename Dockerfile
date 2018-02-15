FROM ruby:2.4.3

ENV LC_ALL C.UTF-8

RUN mkdir -p /app/vendor
WORKDIR /app
ENV PATH /app/bin:$PATH

COPY Gemfile Gemfile.lock /app/
COPY vendor/cache /app/vendor/cache
RUN bundle install --local -j $(nproc)

COPY . /app/

CMD [ "server" ]
