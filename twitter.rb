require 'sinatra'
require 'data_mapper'

DataMapper.setup(:default, "sqlite:///#{Dir.pwd}/project.db")

set :sessions, true
# set :bind, '0.0.0.0'

class User
	include DataMapper::Resource
	property :id, Serial
	property :username, String
	property :password, String
end

class Tweets
	include DataMapper::Resource
	property :tweet_id, Serial
	property :content, String
	property :counter, Integer
	property :user_id, Integer
end

class Followers
	include DataMapper::Resource
	property :id, Serial
	property :follower_id, Integer
	property :following_id, Integer
end

class Likes
	include DataMapper::Resource
	property :id, Serial
	property :tweet_id, Integer
	property :liker_id, Integer
end

DataMapper.finalize
User.auto_upgrade!
Tweets.auto_upgrade!
Followers.auto_upgrade!
Likes.auto_upgrade!

get '/test' do
	"It Works"
end

#Login, logout

get '/' do
	user = nil
	if session[:user_id] 
		user = User.get(session[:user_id])
	else
		redirect '/signin'
	end

	my_tweets = Tweets.all(:user_id => user.id)
	erb :default, locals: {user: user, my_tweets: my_tweets}
end

get '/signup' do
	erb :signup
end

post '/register' do 
	username = params[:username]
	password = params[:password]

	user = User.all(:username => username).first

	if user
		redirect '/signup'
	else
		user = User.new            # Creating a field for new user
		user.username = username
		user.password = password
		user.save
		session[:user_id] = user.id
		redirect '/'
	end
end


post '/logout' do
	session[:user_id] = nil
	redirect '/'
end


get '/signin' do
	erb :signin
end

post '/signin' do

	username = params[:username]
	password = params[:password]

	user = User.all(:username => username).first

	if user
		if user.password == password
			session[:user_id] = user.id
			redirect '/'
		else
			redirect '/signin'
		end
	else
		redirect '/signup'
	end
	redirect '/'
end

#Tweets

post '/add_tweet' do
	content = params[:content]
	tweet = Tweets.new               # Creating a field for new tweet
	tweet.content=content
	tweet.user_id = session[:user_id]
	tweet.counter=0       
	tweet.save
	puts tweet
	redirect '/'
end

post '/followers' do
	user = User.get(session[:user_id]) # I get the user with the current session_id
	my_followers_id = Followers.all(:following_id => user.id)
	my_followers = []
	my_followers_id.each do |my_follower_obj|
		my_followers<<User.get(my_follower_obj.follower_id.to_i)
	end
	erb :followers, locals: {my_followers: my_followers, user: user}
end

post '/following' do 
	user = User.get(session[:user_id])
	follow_id = Followers.all(:follower_id => user.id)
	following = []
	follow_id.each do |following_obj|
		following<<User.get(following_obj.following_id.to_i)
	end
	erb :follows, locals: {following: following, user: user}
end


post '/follow' do
	uname = params[:name]
	user = User.get(session[:user_id]) # I get the user with the current session_id
	user_obj = User.first(:username => uname)
	get_follow=Followers.all(:following_id => user_obj.id)
	get_follow.each do |var|
		if var.follower_id==user.id
			redirect '/'
		end
	end
	follower_obj= Followers.new
	follower_obj.follower_id=user.id
	follower_obj.following_id=user_obj.id
	follower_obj.save
	redirect '/'
end

post '/all_tweets' do
	user = User.get(session[:user_id]) # I get the user with the current session_id
	follow_id = Followers.all(:follower_id => user.id)
	erb :all_tweets, locals: {follow_id: follow_id}
end

post '/like' do
	tweet_id = params[:tweet_id].to_i
	user = User.get(session[:user_id])
	tweet_obj = Tweets.get(tweet_id)
	get_like=Likes.all(:liker_id => user.id)
	get_like.each do |var|
		if var.tweet_id==tweet_id
			redirect '/'
		end
	end
	likes_obj = Likes.new
	likes_obj.tweet_id = tweet_id
	tweet_obj.counter+=1
	likes_obj.liker_id = user.id
	likes_obj.save
	tweet_obj.save
	redirect '/'
end

get '/view_likers' do
	user = User.get(session[:user_id])
	tweet_id = params[:tweet_id].to_i
	likes = Likes.all(tweet_id: tweet_id)
	likers=[]
	likes.each do |likes_obj|
		likers<<User.get(likes_obj.liker_id.to_i)
	end
	erb :view_likers, locals: {likers:likers}
end

post '/remove_tweet' do
	user = User.get(session[:user_id])
	tweet_id=params[:tweet_id].to_i
	tweet_obj=Tweets.get(tweet_id)
	if(tweet_obj.user_id==user.id)
		tweet_obj.destroy
		redirect '/'
	end
end