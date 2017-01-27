#!/usr/bin/env ruby
# frozen_string_literal: true
require 'melora'
require 'sinatra'
require 'redis-store'

r = Redis::Store.new

get '/' do
  "What's an updog?"
end

get '/roll/:game/:dice_string' do
  game_id = params[:game].gsub(/[^\w]/, '')
  pool = Melora::DicePool.new(Melora::String.parse_d_notation_string(params[:dice_string]))
  result = pool.roll
  # i'm probably setting myself up for the redis equivalent of a sql-injection here.
  r.lpush("roll:#{game_id}", "#{params[:dice_string]}: #{result.join(', ')}")
  result.join ', '
end

get '/roll/:dice_string' do
  pool = Melora::DicePool.new(Melora::String.parse_d_notation_string(params[:dice_string]))
  pool.roll.join ', '
end
