#require Geocoder

class TweetsController < ApplicationController
  before_action :set_tweet, only: [:show, :edit, :update, :destroy]

  # GET /tweets
  # GET /tweets.json
  def index
    # TODO: Add parameter validation
    #       Improve handling of defaults
    size = (params[:size] || 250).to_i
    location = params[:location]
    keywords = params[:keywords]
    radius = (params[:radius] || 200).to_i

    radius = 200 if radius == 0
    location = nil if location && location.length == 0
    if location && location.length >0
      location = Geocoder.coordinates(params[:location])
    end
    unless keywords.nil?
      keywords = keywords.strip
      keywords = nil if keywords.length == 0
    end

    fields = ['user.screen_name', 'user.name',
              'user.profile_image_url', 'text', 'geo']

    tweets = Tweet.top_tweets(location, keywords, fields, size, radius)
    @hash = Gmaps4rails.build_markers(tweets) do |tweet, marker|
      marker.lat tweet.geo['coordinates']['lat']
      marker.lng tweet.geo['coordinates']['lon']
      marker.infowindow ["<b>@#{tweet.user['screen_name']}</b>", tweet.text].join(': ')
      marker.picture({
                       "url" => tweet.user['profile_image_url'],
                       "width" =>  32,
                       "height" => 32})
      marker.json({id: tweet.id, screen_name: tweet.user['screen_name'],
                   text: tweet.text, coordinates: tweet.geo['coordinates'],
                   user_name: tweet.user['name'],
                   pic: tweet.user['profile_image_url']})
    end
  end

  # GET /tweets/1
  # GET /tweets/1.json
  def show
  end

  # GET /tweets/new
  def new
    @tweet = Tweet.new
  end

  # GET /tweets/1/edit
  def edit
  end

  # POST /tweets
  # POST /tweets.json
  def create
    @tweet = Tweet.new(tweet_params)

    respond_to do |format|
      if @tweet.save
        format.html { redirect_to @tweet, notice: 'Tweet was successfully created.' }
        format.json { render :show, status: :created, location: @tweet }
      else
        format.html { render :new }
        format.json { render json: @tweet.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tweets/1
  # PATCH/PUT /tweets/1.json
  def update
    respond_to do |format|
      if @tweet.update(tweet_params)
        format.html { redirect_to @tweet, notice: 'Tweet was successfully updated.' }
        format.json { render :show, status: :ok, location: @tweet }
      else
        format.html { render :edit }
        format.json { render json: @tweet.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tweets/1
  # DELETE /tweets/1.json
  def destroy
    @tweet.destroy
    respond_to do |format|
      format.html { redirect_to tweets_url, notice: 'Tweet was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tweet
      @tweet = Tweet.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def tweet_params
      params[:tweet]
    end
end
