FROM ruby:2.2.0

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev
RUN mkdir /tweet-sieve

WORKDIR /tweet-sieve

ADD Gemfile /tweet-sieve/Gemfile
ADD Gemfile.lock /tweet-sieve/Gemfile.lock

RUN bundle install

ADD . /tweet-sieve

EXPOSE 3000
