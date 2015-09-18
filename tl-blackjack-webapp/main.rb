require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session', :path => '/', :secret => 'torch'
BLACKJACK = 21
DEALER_STAY_NUMBER = 17

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
      sum -= 10 if sum > BLACKJACK
      end
    sum
  end

  def card_image(card)
    suit = case card[1]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
      when 'S' then 'spades'
    end

    value = card[0]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[0]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end
    end
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end

  def winner!(msg)
    @show_play_again_button = true
    @show_hit_or_stay_buttons = false
    @success = "<strong>#{session[:player_name]} wins! $#{session[:player_bet]}</strong> #{msg}"
    session[:player_money] = session[:player_money] + session[:player_bet]
    @succces = "You now have $#{session[:player_money]}"
  end

  def loser!(msg)
    @show_play_again_button = true
    @show_hit_or_stay_buttons = false
    session[:player_money] = session[:player_money] - session[:player_bet]
    @error = "You lost $#{session[:player_bet]} You now have $#{session[:player_money]}"
    @error = "<strong>#{session[:player_name]} loses $#{session[:player_bet]}</strong> #{msg}"
    
    if session[:player_money] == 0
      @error = "It seems you have run out of money, you can start over if you want."
    end
  end

  def tie!(msg)
    @show_play_again_button = true
    @show_hit_or_stay_buttons = false
    @success = "<strong>It's a tie!</strong> #{msg}"
  end
end

before do
  @show_hit_or_stay_buttons = true
end

get '/' do
  if session[:player_name]
    redirect '/set_bet'
  else
    redirect '/set_name'
  end
end

get '/set_name' do
  erb :set_name
end

post '/set_name' do
  if params[:player_name].empty?
    @error = "A name is required to proceed!"
    halt erb(:set_name)
  end
    session[:player_name] = params[:player_name]
    session[:player_money] = 1000
    redirect '/set_bet'
end

get '/set_bet' do
  erb :set_bet
end

post '/set_bet' do
  if params[:player_bet].empty? || params[:player_bet].to_i == 0
    @error = "You need to enter an amount of 1 or more!"
    halt erb :set_bet
  elsif params[:player_bet].to_i < 0
    @error = "You can't enter negative numbers!"
    halt erb :set_bet
  elsif params[:player_bet].to_i > session[:player_money]
    @error = "You can't bet more than what you have. You only have #{session[:player_money]}."
    halt erb :set_bet
  end
  session[:player_bet] = params[:player_bet].to_i
  redirect '/game'
end

get '/game' do
  session[:turn] = session[:player_name]

  CARDS = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  SUIT = ['H', 'C', 'D', 'S']

  session[:deck] = CARDS.product(SUIT).shuffle!
  session[:player_cards] = []
  session[:dealer_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop

  player_total = calculate_total(session[:player_cards])

  if player_total == BLACKJACK
    winner!("#{session[:player]} You hit blackjack!")
  end
  erb :game #rendering the template
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK
    winner!("#{session[:player]} You hit blackjack!")
  elsif player_total > BLACKJACK
    loser!("it looks like #{session[:player]} busted at #{player_total}")
  end
  erb :game
end

post '/game/player/stay' do
  @success = "#{session[:player_name]} has chosen to stay."
  @show_hit_or_stay_buttons = false
  redirect 'game/dealer'
end

get '/game/dealer' do
  session[:turn] = "dealer"
  @success = "#{session[:player_name]} has chosen to stay, Dealers turn."
  @show_hit_or_stay_buttons = false

  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total == BLACKJACK
    loser!("Dealer hit blackjack")
  elsif dealer_total > BLACKJACK
    winner!("Dealer busted at #{dealer_total}.")
  elsif dealer_total >= DEALER_STAY_NUMBER
    redirect '/game/compare'
  else
    @show_dealer_hit_button = true
  end
  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do

  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if player_total < dealer_total
    loser!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  elsif player_total > dealer_total
    winner!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  else
    tie!("both #{session[:player_name]} and the dealer stayed at #{player_total}.")
  end
  erb :game
end

get '/game_over' do
  erb :game_over
end