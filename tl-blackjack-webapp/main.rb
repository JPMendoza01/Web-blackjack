require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'torch'

helpers do 
  def calculate_total(hand)
    arr = hand.map{ |x| x[0] }
  
    sum = 0
    arr.each do |value|
      if value == 'A'
      sum += 11
      elsif value.to_i == 0
        sum += 10
      else
        sum += value.to_i
      end
    end
  
    arr.select{|x| x == 'A'}.count.times do
      sum -= 10 if sum > 21
      end
    sum
  end
end

get '/' do
  erb :set_name
end

post '/set_name' do
  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  CARDS = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  SUIT = ['of Hearts', 'of Clubs', 'of Diamonds', 'of Spades']

  session[:deck] = CARDS.product(SUIT)
  session[:deck].shuffle!
  session[:player_cards] = []
  session[:player_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  
  erb :game
end

