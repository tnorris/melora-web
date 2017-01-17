#!/usr/bin/env ruby
# frozen_string_literal: true
require 'melora'
require 'sinatra'

get '/' do
  "What's an updog?"
end

get '/roll/:dice_string' do
  pool = Melora::DicePool.new(Melora::String.parse_d_notation_string(params[:dice_string]))
  pool.roll.join ', '
end
