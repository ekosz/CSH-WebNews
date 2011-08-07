class Post < ActiveRecord::Base
  belongs_to :newsgroup, :foreign_key => :newsgroup, :primary_key => :name
  has_many :unread_post_entries, :dependent => :destroy
  
  def parent
    Post.where(:message_id => references, :newsgroup => newsgroup.name).first
  end
  
  def children
    Post.where(:references => message_id, :newsgroup => newsgroup.name).order('date')
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
  
  def self.import!(newsgroup, number, headers, body)
    attachments_stripped = false
    headers.gsub!(/\n( |\t)/, ' ')
  
    if headers[/^Content-Type: multipart/i]
      boundary = Regexp.escape(headers[/^Content-Type:.*boundary ?= ?"?([^"]+?)"?(;|$)/i, 1])
      match = /.*?#{boundary}\n(.*?)\n\n(.*?)\n(--)?#{boundary}/m.match(body)
      headers += "\n--- Message part headers follow ---\n" + match[1].gsub(/\n( |\t)/, ' ')
      body = match[2]
      attachments_stripped = true if headers[/^Content-Type:.*mixed/i]
    end
    
    body = body.unpack('M')[0] if headers[/^Content-Transfer-Encoding: quoted-printable/i]
    
    if headers[/^Content-Type:.*(X-|unknown)/i]
      body.encode!('UTF-8', 'US-ASCII', :invalid => :replace, :undef => :replace)
    elsif headers[/^Content-Type:.*charset/i]
      begin
        body.encode!('UTF-8', headers[/^Content-Type:.*charset="?([^"]+?)"?(;|$)/i, 1],
          :invalid => :replace, :undef => :replace)
      rescue
        body.encode!('UTF-8', 'US-ASCII', :invalid => :replace, :undef => :replace)
      end
    else
      begin
        body.encode!('UTF-8', 'US-ASCII') # RFC 2045 Section 5.2
      rescue
        begin
          body.encode!('UTF-8', 'Windows-1252')
        rescue
          body.encode!('UTF-8', 'US-ASCII', :invalid => :replace, :undef => :replace)
        end
      end
    end
    
    if body[/^begin(-base64)? \d{3} /]
      body.gsub!(/^begin \d{3} .*?\nend\n/m, '')
      body.gsub!(/^begin-base64 \d{3} .*?\n====\n/m, '')
      attachments_stripped = true
    end
    
    body = flowed_decode(body) if headers[/^Content-Type:.*format="?flowed"?/i]
    body += "\n\n--- Attachments stripped by WebNews ---" if attachments_stripped
    
    subject = first_line = headers[/^Subject: (.*)/i, 1]
    references = headers[/^References: (.*)/i, 1].to_s.split[-1] || ''
    
    if references != '' and
        not where(:message_id => references, :newsgroup => newsgroup.name).exists?
      references = ''
    end
    
    if subject[/^Re:/i] and references != ''
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
            :author => headers[/^From: (.*)/i, 1],
            :date => DateTime.parse(headers[/^Date: (.*)/i, 1]),
            :message_id => headers[/^Message-ID: (.*)/i, 1],
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
