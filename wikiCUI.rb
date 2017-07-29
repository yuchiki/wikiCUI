require 'uri'
require 'httpclient'
require 'mechanize'
require 'optparse'

op = OptionParser.new
lang = []
op.on('-l value') { |v| lang << v }
op.parse! ARGV

path = File.dirname __FILE__
lang += File.read("#{path}/default_languages.txt").split
agent = Mechanize.new
doc = nil
lang.each do |l|
  begin
    addr = "https://#{l}.wikipedia.org/wiki/#{URI.escape ARGV.join('_')}"
    STDERR.puts "Fetching from #{addr}..."
    doc = Nokogiri::HTML agent.get(addr).content.toutf8
    STDERR.puts "Fetched from #{addr}."
    break
  rescue Mechanize::ResponseCodeError => e
    case e.response_code
    when '404'
      next
    end
  rescue SocketError => e
    STDERR.puts e.message
  end
end

if doc.nil?
  STDERR.puts 'article not found.'
  exit
end

maintexts = doc.xpath('//div[@class="mw-parser-output"]').children
abstract =  maintexts.reject { |x| x.name == 'text' }
                     .drop_while { |x| x.name != 'p' }
                     .take_while { |x| x.name == 'p' }
                     .map(&:text).join "\n"
puts abstract.gsub(/{\\.*}/, '').gsub(/\[.*\]/, '').delete "\n"
