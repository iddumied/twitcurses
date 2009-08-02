#!/usr/bin/env ruby

# TODO
#   - different colors for individuals
#   - show current length of the tweet/character count
#   - url shortner
#   - mentions page
#       - all the mentions
#       - color. if a reply has been made then normal
#               if a reply has not been made then yellow or red
#   - search
#   - followers
#       - list followers
#       - add followers
#       - remove followers
#   - direct message
require 'date'
require 'rubygems'
require 'yaml'
require 'curses'
require 'twitter'

ConfigFile = "#{ENV['HOME']}/.twitcurses"

def header
  Curses::addstr("Twitcurses by abhiyerra\n\n")
end

def create_refresher_thread
  @refresher = Thread.new do 
    loop do
      update_timeline
      Curses.refresh
      sleep @config["refresh-rate"]
    end
  end
end

def destroy_refresher_thread
  Thread.kill @refresher
end

def restart_refresher_thread
  destroy_refresher_thread
  create_refresher_thread
end

def update_timeline
  Curses.clear
  header
  Curses.addstr "Last updated: #{Time.now}\n"

  @twitter.friends_timeline.each do |tweet|
    tweet_text = "#{tweet.user.screen_name}: #{tweet.text}\n"
    Curses.addstr tweet_text

    if @updated_time <= DateTime.parse(tweet.created_at)
      unless @mute_say
        `say "#{tweet_text}"`
      end
    end
  end

  @updated_time = DateTime.parse(Time.now.to_s)
end

def show_user_tweets
  destroy_refresher_thread

  Curses.clear
  Curses.addstr "\n"
  Curses.addstr "Type the screen name for user or press enter a regex to find user? "
  screen_name = Curses.getstr

  @twitter.user_timeline(:screen_name => screen_name).each do |tweet|
    tweet_text = "#{tweet.user.screen_name}: #{tweet.text}\n"
    Curses.addstr tweet_text
  end

  Curses.getch

  create_refresher_thread
end

def new_tweet
  destroy_refresher_thread

  Curses.deleteln
  Curses.addstr "\n"
  Curses.addstr "Enter a tweet or empty line to cancel: "
  new_tweet = Curses.getstr

  unless new_tweet.eql? ''
    @twitter.update(new_tweet)
  end

  create_refresher_thread
end

def mute_say
  @mute_say = !@mute_say
end

begin
  @config = YAML::load_file(ConfigFile)

  @twitter = Twitter::Base.new(Twitter::HTTPAuth.new(@config["username"], @config["password"]))
  
  @updated_time = DateTime.parse(Time.now.to_s)
  @mute_say = false
  
  Curses.init_screen
  Curses.start_color
  Curses.setpos(0, 0)

  create_refresher_thread

  while true
    c = Curses.getch

    case c
    when ?\e
      restart_refresher_thread
    when ?U
      show_user_tweets
    when ?T
      new_tweet
    when ?M
      mute_say
    when ?Q
      Curses.clear
      exit
    end
  end 

  Curses.clear
end
