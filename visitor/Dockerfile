FROM ruby:2.6
ENV APP_PATH=/usr/src
WORKDIR $APP_PATH
COPY Gemfile* $APP_PATH/
RUN bundle install
COPY . .
CMD ["ruby", "./app/visitors.rb"]