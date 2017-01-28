#!/usr/bin/env ruby
# frozen_string_literal: true
require 'melora'
require 'sinatra'
require 'redis-store'

get '/' do
  "What's an updog?"
end

helpers do
  def redis
    @redis ||= Redis::Store.new
  end

  def humans
    %w(dm player)
  end

  def push_roll_to_redis(params, result)
    game_id = params[:game].gsub(/[^\w]/, '')
    # should probably do more validation on dice_string incase melora ever stops
    redis.lpush("roll:#{game_id}",
                "#{@player_name}: #{params[:dice_string]}: #{result.join(', ')}")
    result.join ', '
  end

  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||= Rack::Auth::Basic::Request.new(request.env)
    halt 401 unless @auth.provided? && @auth.basic? && @auth.credentials
    halt 401 unless humans.include? @auth.credentials.last
    @player_name = @auth.credentials.first
  end
end

get '/roll/:game/:dice_string' do
  pool = Melora::DicePool.new(Melora::String.parse_d_notation_string(params[:dice_string]))
  result = pool.roll
  push_roll_to_redis params, result
end

get '/roll-without-explosions/:game/:dice_string' do
  protected!
  d_notation_hash = Melora::String.parse_d_notation_string(params[:dice_string])
  pool = Melora::DicePool.new(d_notation_hash.merge(exploding: false))
  result = pool.roll
  push_roll_to_redis params, result
end

get '/view_rolls/:game' do
  game_id = params[:game].gsub(/[^\w]/, '')
  @roll_list = redis.lrange("roll:#{game_id}", 0, -1)
  erb :view_rolls
end

get '/roll/:dice_string' do
  pool = Melora::DicePool.new(Melora::String.parse_d_notation_string(params[:dice_string]))
  pool.roll.join ', '
end
