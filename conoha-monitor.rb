require 'fluent-logger'
require 'nokogiri'
require 'net/https'
require 'open-uri'
require 'json'

target_url = ENV['CONOHA_MONITOR_TARGET'] || 'https://cp.conoha.jp/information.aspx'
DETAIL_ENDPOINT = ENV['CONOHA_MONITOR_DETAIL_URL'] || 'https://cp.conoha.jp/GetInforMation.aspx?mid=%s'
PERMALINK = ENV['CONOHA_MONITOR_PERMALINK'] || 'https://cp.conoha.jp/Information.aspx#%s'
tag_prefix = ENV['CONOHA_MONITOR_TAG_PREFIX'] || 'conoha-monitor'
interval = (ENV['CONOHA_MONITOR_INTERVAL'] || 180).to_i
fluentd_host, fluentd_port = ENV['CONOHA_MONITOR_FLUENTD'] ? ENV['CONOHA_MONITOR_FLUENTD'].split(':', 2) : ['localhost', 24224]

@logger = Fluent::Logger::FluentLogger.new(tag_prefix, host: fluentd_host, port: fluentd_port.to_i)
def log(*args)
  p args
  @logger.post *args
end

# ---

def news_detail(id)
  url = DETAIL_ENDPOINT % id
  news = JSON.parse(open(url, 'r', &:read))

  {
    kind: news['categoryCssClass'],
    title: news['subject'],
    at: Time.parse(news['date']),
    body: news['body'].gsub(/\r\n/,"\n"),
  }
end

last = nil
loop do
  begin
    page = Nokogiri::HTML(open(target_url, 'r', 'Cookie' => 'conoha-culture-info=ja', &:read))
    newslist = page.at('.newsList').search('dt,dd').each_slice(2).map {|(dt,dd)| id = dd.at('a')['href'][1..-1]; {id: id, kind: dt['class'], at: dt.inner_text, title: dd.inner_text, url: PERMALINK % id} }

    latest_news = newslist.first

    unless last
      if ENV['CONOHA_MONITOR_DEBUG'] == '1'
        last = newslist[1][:id]
      else
        last = latest_news[:id]
        puts "Watching for news, after #{latest_news.inspect}"
      end
    end

    if last != latest_news[:id]
      puts "Found new news"
      last_index = newslist.index { |_| _[:id] == last }

      newslist[0...last_index].each do |news|
        news.merge!(news_detail(latest_news[:id]))
        message = "#{news[:kind]}: #{news[:title]} #{news[:url]}\n\n```\n#{news[:body]}\n```"
        puts "----"
        puts message
        log("news.#{news[:kind]}", news.merge(message: message))
        puts "----"
      end
    end

    last = latest_news[:id]
    sleep interval
  rescue Interrupt
    raise
  rescue Exception => e
    log("error", {class: e.class, message: e.message, backtrace: e.backtrace})
    puts "#{e.inspect}\n\t#{e.backtrace.join("\n\t")}"
    sleep interval
  end
end
