require "database"
require "models"
require "rubygems"
require "feedzirra"
require "rest_client"
require "json"
require "pp"
require "rss/maker"
require "tzinfo"
include Feedzirra

posts = DB.from :posts
posts_urls = posts.map do |p|
  p[:url]
end

feed = Feed.fetch_and_parse("http://feedproxy.google.com/TechCrunch")

tz = TZInfo::Timezone.get('America/New_York')
feed.entries.each do |e|
  # next if already on DB
  if posts_urls.include?(e.url)
    puts "Updating for `#{e.title}'"
    post = Post[:url => e.url]
    post.update(
      :title => e.title,
      :content => e.content,
      :published => tz.utc_to_local(e.published).strftime('%Y-%m-%d %H:%M:%S'),
      :updated_at => 'NOW()'
    )
    next
  end
  
  # next if story is younger than 2 hours
  # next if (Time.now - e.published) < 2.hours
  
  buf = RestClient.post("http://api.tweetmeme.com/url_info.json", :url => e.url)
  res = JSON.parse(buf.to_s)
  next if res['story']['url_count'].to_i < 800
  
  puts "Inserting... `#{e.url}'"
  posts.insert(
    :title => e.title,
    :url => e.url,
    :title => e.title,
    :content => e.content,
    :published => tz.utc_to_local(e.published).strftime('%Y-%m-%d %H:%M:%S'),
    :created_at => :now.sql_function,
    :updated_at => :now.sql_function
  )

end

posts = DB.from(:posts).reverse_order(:published)

version = "2.0"
destination = "techcrunch.rss"
 
content = RSS::Maker.make(version) do |m|
  m.channel.title = "TechCrunch (top stories)"
  m.channel.link = "http://www.techcrunch.com/"
  m.channel.description = "TechCrunch is a group-edited blog that profiles the companies, products and events defining and transforming the new web."
  m.items.do_sort = true

  posts.each do |p|
    i = m.items.new_item
    i.title = p[:title]
    i.link = p[:url]
    i.description = p[:content]
    i.date = p[:published]
  end
end
 
File.open(destination, "w") do |f|
  f.write(content)
end
