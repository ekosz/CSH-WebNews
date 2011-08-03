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
    body.encode!('UTF-8', headers[/Content-Type:.*charset="?([^"]+?)"?(;|$)/, 1],
      :invalid => :replace, :undef => :replace) if headers[/Content-Type:.*charset/]
    body = flowed_decode(body) if headers[/Content-Type:.*format="?flowed"?/]
    body += "\n\n[Attachment stripped by WebNews]" if attachment_stripped
    
    create!(:newsgroup => newsgroup,
            :number => number,
            :subject => headers[/Subject: (.*)/, 1],
            :author => headers[/From: (.*)/, 1],
            :date => DateTime.parse(headers[/Date: (.*)/, 1]),
            :message_id => headers[/Message-ID: (.*)/, 1],
            :references => headers[/References: (.*((\n\t+.*)+)?)/, 1].to_s.split[-1] || '',
            :headers => headers,
            :body => body)
  end
  
  # See RFC 3676 for "format=flowed" spec
  
  def self.flowed_decode(body)
    new_body_lines = []
    body.split("\n").each do |line|
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
