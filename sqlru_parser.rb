class SqlruParser

  require 'Typhoeus'
  require 'Nokogiri'

  def parse_page(noko,file)
    posts = noko.css('table.msgTable')

    posts.each do |post|
      next unless nick = post.css('tr')[1].css('a').first
      nick = nick.text.gsub("\r\n",'').gsub(/^\s+/,'').gsub(/\s+$/,'')
      next unless nick == 'NePZ'
      file.write(post)
    end
  end

  def save_topic(nickname,url)
    topic_name = url.match(/\/[^\/]+$/)[0].match(/[a-z|0-9|\-]+/)[0]
    file = File.open("#{nickname}/#{topic_name}.html",'w')
    # file.write("<link rel=\"stylesheet\" type=\"text/css\" href=\"../main.css\" media=\"screen\">")
    file.write("<style>\n")
    file.write(@css)
    file.write("</style>\n")

    while url do
      puts "parse url: #{url}"
      page = Typhoeus.get(url)
      noko = Nokogiri::HTML(page.body)
      parse_page(noko, file)
      if noko.css('a#urlForumNext').any?
        url = noko.css('a#urlForumNext').first.attributes["href"].value
      else
        url = nil
      end
    end

    page = Typhoeus.get(url)
    file.close
  end

  def get_urls(nickname)
    urls = []
    first_urlpage_url = "http://www.sql.ru/forum/actualsearch.aspx?a=#{nickname}&ma=1&pg=1"
    page = Typhoeus.get(first_urlpage_url)
    noko = Nokogiri::HTML(page.body)
    other_url_pages = noko.css("table.forumtable_results").last.css('a').map{|n| n.attributes["href"].value}
    other_url_pages = other_url_pages.map{|s| "http://www.sql.ru/forum/#{s}"}
    url_pages = [first_urlpage_url] + other_url_pages

    url_pages.each_with_index do |urlpage_url, index|
      page = Typhoeus.get(urlpage_url) if index != 0
      noko = Nokogiri::HTML(page.body)
      topics = noko.css("td.postslisttopic")
      topics.each do |topic|
        urls << topic.css('a').first.attributes["href"].value
      end
    end
    return urls
  end

  def go(nickname)
    css = File.open("main.css", 'r')
    @css = css.read
    css.close
    time = Time.now
    puts 'start'
    begin
      Dir.mkdir(nickname)
    rescue Exception => e
      puts e
    end
    urls = get_urls(nickname)
    puts "found urls: #{urls.count}"
    urls.each do |url|
      save_topic(nickname,url)
    end
    puts "end, total time: #{(Time.now - time).to_i} seconds"
  end
end



puts SqlruParser.new().go('NePZ')

# SqlruParser.new().save_topic('NePZ',"http://www.sql.ru/forum/1187320/dopolnennaya-realnost?hl=")
