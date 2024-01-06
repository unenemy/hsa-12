FROM ruby:3.1.4

WORKDIR /app
COPY . /app
RUN bundle install

ENTRYPOINT [ "ruby", "test.rb" ]
