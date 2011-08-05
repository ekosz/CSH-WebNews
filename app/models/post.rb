class Post < ActiveRecord::Base
  set_primary_keys :newsgroup, :number
  belongs_to :newsgroup, :foreign_key => :newsgroup, :primary_key => :name
  
  def parent
    Post.where(:message_id => references, :newsgroup => newsgroup.name).first
  end
  
  def children
    Post.where(:references => message_id).order('date')
  end
  
  def thread_parent
    if references == ''
      self
    else
      parent.thread_parent
    end
  end
  
  def authored_by?(user)
    author_name == user.real_name or author_email == user.email
  end
  
  def user_in_thread?(user)
    return true if authored_by?(user)
    children.each do |child|
      return true if child.user_in_thread?(user)
    end
    return false
  end
  
  def author_name
    author[/"?(.*?)"? <.*>/, 1] || author[/.* \((.*)\)/, 1] || author
  end
  
  def author_email
    author[/"?.*?"? <(.*)>/, 1] || author[/(.*) \(.*\)/, 1] || nil
  end
  
  def short_headers
    [
      headers[/From: .*/],
      headers[/Date: .*/],
      headers[/Subject: .*/],
      headers[/Message-ID: .*/]
    ].join("\n")
  end
  
  def html_body
    hbody = ''
    quote_depth = 0
    body.each_line do |line|
      depth_change = (line[/^>[> ]*/] || '').gsub(/\s/, '').length - quote_depth
      line = CGI.escapeHTML(line.chomp)
      if depth_change > 0
        line = ('<blockquote>' * depth_change) + line
      elsif depth_change < 0
        line += ('</blockquote>' * depth_change.abs)
      end
      quote_depth += depth_change
      hbody += line + "\n"
    end
    return hbody
  end
  
  def self.import!(newsgroup, number, headers, body)
    attachment_stripped = false
  
    if headers[/Content-Type: multipart/]
      boundary = headers[/Content-Type:.*boundary="?([^"]+)"?/, 1]
      match = /.*?#{boundary}\n(.*?)\n\n(.*?)\n(--)?#{boundary}/m.match(body)
      headers += "\n[Message part headers begin here]\n" + match[1]
      body = match[2]
      attachment_stripped = true if headers[/Content-Type:.*mixed/]
    end
    
    body = body.unpack('M')[0] if headers[/Content-Transfer-Encoding: quoted-printable/]
    if headers[/Content-Type:.*charset/]
      body.encode!('UTF-8', headers[/Content-Type:.*charset="?([^"]+?)"?(;|$)/, 1],
        :invalid => :replace, :undef => :replace)
    elsif headers[/X-Newsreader: Microsoft Outlook Express/]
      body.encode!('UTF-8', 'Windows-1252')
    else
      body.encode!('UTF-8', 'US-ASCII') # RFC 2045 Section 5.2
    end
    body = flowed_decode(body) if headers[/Content-Type:.*format="?flowed"?/]
    body += "\n\n[Attachment stripped by WebNews]" if attachment_stripped
    
    subject = first_line = headers[/Subject: (.*)/, 1]
    references = headers[/References: (.*((\n\t+.*)+)?)/, 1].to_s.split[-1] || ''
    
    if subject[/^Re:/i] and references != '' and where(:message_id => references).exists?
      body.each_line do |line|
        if not (line.blank? or line[/^>/] or line[/(wrote|writes):$/] or
            line[/^In article/] or line[/^On.*\d{4}.*:/] or line[/wrote in message/] or
            line[/news:.*\.\.\.$/] or line[/^\W*snip\W*$/])
          first_line = line.chomp
          first_line = first_line.sub(/ +$/, '') + '...' if not first_line[/[.?!:] *$/]
          break
        end
      end
    end
    
    create!(:newsgroup => newsgroup,
            :number => number,
            :subject => subject,
            :author => headers[/From: (.*)/, 1],
            :date => DateTime.parse(headers[/Date: (.*)/, 1]),
            :message_id => headers[/Message-ID: (.*)/, 1],
            :references => references,
            :first_line => first_line,
            :headers => headers,
            :body => body)
  end
  
  # See RFC 3676 for "format=flowed" spec
  
  def self.flowed_decode(body)
    new_body_lines = []
    body.each_line do |line|
      line.chomp!
      quotes = line[/^>+/]
      line.sub!(/^>+/, '')
      line.sub!(/^ /, '')
      if line != '-- ' and
          new_body_lines.length > 0 and
          !new_body_lines[-1][/^-- $/] and
          new_body_lines[-1][/ $/] and
          quotes == new_body_lines[-1][/^>+/]
        new_body_lines[-1] << line
      else
        new_body_lines << quotes.to_s + line
      end
    end
    return new_body_lines.join("\n")
  end
end
