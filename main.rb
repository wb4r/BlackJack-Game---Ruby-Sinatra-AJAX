require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie,  :key => 'rack.session',
                            :path => '/',
                            :secret => 'wzjfeno43634245mvaldise9r0373'

# HELPERS

helpers do 

  def create_deck
    suits = %w[H D C S]
    cards = %w[2 3 4 5 6 7 8 9 10 J Q K A]
    deck = suits.product(cards)
    session[:deck] = deck.shuffle!
  end

  def provide_card(hand)
    session[hand] << session[:deck].pop
  end

  def create_hands
    session[:dealer_hand] = []
    session[:player_hand] = []
  end

  def first_hand
    2.times do 
      provide_card(:dealer_hand)
      provide_card(:player_hand)
    end
  end

  def calculate_total(hand)
    total = []
    hand.each do |card|
      if card[1] == 'J' || card[1] == 'Q' || card[1] == 'K' 
        total << 10
      elsif card[1] == 'A' 
        total << 11
      else
        total << card[1].to_i
      end
    end
    while total.inject(:+) > 21 && total.max == 11
      total.sort!
      total.pop
      total << 1
    end

    total.inject(:+)
  end

  def card_image(card)
    suit = case card[0]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
      when 'S' then 'spades'
    end

    value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[1]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end
    end
    "<img class='img-thumbnail' src='/images/cards/#{suit}_#{value}.jpg'>"
  end

  def dealer_to_17 
    session[:dealer_total] = calculate_total(session[:dealer_hand])
    while session[:dealer_total] < 17
      provide_card(:dealer_hand)
      session[:dealer_total] = calculate_total(session[:dealer_hand])
    end
    session[:dealer_total]
  end
  
  def decrease_money
    session[:total_money] = session[:total_money] - session[:bet_amount]
  end
  
  def increase_money
      session[:total_money] = session[:total_money] + session[:bet_amount]      
  end

  def switch_buttons
    @show_hit_or_stay_buttons = false
    @show_replay_btn = true
  end

  def show_dealer_cards
    @show_dealer_data = true
  end
end

# BEFORES

before do
  @show_hit_or_stay_buttons = true
  @show_dealer_data = false
  @show_replay_btn = false
end

# GAME STARTS

get '/' do 
  if params[:player_name]
    redirect '/bet'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "Sir/Mam, I need your ID to let you in."
    halt erb(:new_player)
  end
  session[:total_money] = 500
  session[:player_name] = params[:player_name].capitalize!
  erb :bet
end

get '/bet' do
  erb :bet
end

post '/bet' do 
  session[:bet_amount] = params[:bet_amount].to_i

  if params[:bet_amount].nil? || params[:bet_amount].to_i == 0
    @error = "Must make a minimum bet."
    halt erb(:bet)
  elsif params[:bet_amount].to_i > session[:total_money]
    @error = "Your maximum bet is: #{session[:total_money]}$"
    halt erb(:bet)
  else
    session[:player_bet] = params[:bet_amount].to_i
    redirect '/game'
  end
end

# INITIAL ENGINE - POINT FOR REPLAY

get '/game' do 
  create_deck
  create_hands
  first_hand
  session[:player_total] = calculate_total(session[:player_hand])
  session[:dealer_total] = calculate_total(session[:dealer_hand])
  
  if session[:player_total] == 21
    switch_buttons
    increase_money
    @success = "#{session[:player_name]} hit blackjack."        
  end
  erb :game
end

post '/hit' do
  provide_card(:player_hand)
  player_total = calculate_total(session[:player_hand])
  if player_total == 21
    switch_buttons
    increase_money
    @success = "#{session[:player_name]} hit blackjack."    
  elsif player_total > 21
    switch_buttons
    decrease_money
    @error = "#{session[:player_name]} busted with #{player_total}."    
  end  
  erb :game#, layout: false
end

post '/stay' do
  redirect '/game/dealer'
end

get '/game/dealer' do
  switch_buttons
  dealer_to_17
  dealer_total = calculate_total(session[:dealer_hand])
  
  if dealer_total == 21
    decrease_money
    @error = "Dealer hit blackjack."    
  elsif dealer_total > 21
    increase_money
    @success = "Dealer busted at #{dealer_total}."
  elsif dealer_total >= 17 && dealer_total <= 21
    redirect '/game/comparison'
  end
  show_dealer_cards
  redirect '/game/comparison'
end

get '/game/comparison' do
  switch_buttons
  show_dealer_cards
  player_total = calculate_total(session[:player_hand])
  dealer_total = calculate_total(session[:dealer_hand])

  if player_total <= dealer_total && dealer_total < 21
    decrease_money
    @error = "#{session[:player_name]} lost with #{player_total} against the Dealer with #{dealer_total}."    
  elsif dealer_total == 21
    decrease_money
    @error = "Dealer hit blackjack."
  elsif dealer_total > 21
    increase_money
    @success = "Dealer busted at #{dealer_total}."
  elsif player_total > dealer_total && player_total < 21
    increase_money
    @success = "#{session[:player_name]} won with #{player_total} against the Dealer with #{dealer_total}."
  end
  erb :game#, layout: false
end