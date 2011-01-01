require "rubygems"
require "sequel"

DB = Sequel.connect(
  :adapter => "mysql",
  :username => "topstories",
  :password => "ecgreRGCErgweXRgewrty4fwcg3qf4",
  :database => "topstories"
)
