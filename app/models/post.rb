class Post < ActiveRecord::Base
  belongs_to :newsgroup, :foreign_key => :newsgroup, :primary_key => :name
  has_many :unread_post_entries, :dependent => :destroy
  before_destroy :kill_references
  
  def author_name
    author[/"?(.*?)"? ?<.*>/, 1] || author[/.* \((.*)\)/, 1] || author
  end
  
  def author_email
    author[/"?.*?"? <(.*)>/, 1] || author[/(.*) \(.*\)/, 1] || nil
  end
  
  def quoted_body
    author_name + " wrote:\n\n" +
      body.chomp.sub(/(.*)\n-- \n.*/m, '\\1').
        split("\n").map{ |line| '>' + line }.join("\n") + "\n\n"
  end
  
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
  
  def unread_for_user?(user)
    unread_post_entries.where(:user_id => user.id).any?
  end
  
  def mark_read_for_user(user)
    entry = unread_post_entries.where(:user_id => user.id).first
    if entry
      entry.destroy
      return true
    else
      return false
    end
  end
  
  def thread_unread_for_user?(user)
    if unread_for_user?(user)
      return true
    elsif children.count > 0
      return true if children.reduce(false){ |memo, child| memo && child.thread_unread_for_user?(user) }
    end
    return false
  end
  
  def personal_class_for_user(user)
    case
      when authored_by?(user) then :mine
      when parent && parent.authored_by?(user) then :mine_reply
      when thread_parent.user_in_thread?(user) then :mine_in_thread
    end
  end
  
  def kill_references
    # Sub-optimal, should re-parent to next reference up the chain
    # (but posts getting canceled when they already have replies is rare)
    Post.where(:references => message_id).each do |post|
      post.update_attributes(:references => '', :first_line => post.subject)
    end
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
  
  def self.build_message(p)
    m = "From: #{p[:user].real_name} <#{p[:user].email}>"
    m += "\nSubject: #{p[:subject].encode('US-ASCII', :invalid => :replace, :undef => :replace)}"
    m += "\nNewsgroups: #{p[:newsgroup].name}"
    if p[:reply_post]
      existing_refs = p[:reply_post].headers[/^References: (.*)/i, 1]
      existing_refs ? existing_refs += ' ' : existing_refs = ''
      m += "\nReferences: #{existing_refs + p[:reply_post].message_id}"
    end
    m += "\nContent-Type: text/plain; charset=utf-8; format=flowed"
    m += "\nUser-Agent: CSH-WebNews"
    m += "\n\n#{flowed_encode(p[:body])}"
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
  
  def self.flowed_encode(body)
    body.split("\n").map do |line|
      line.rstrip!
      quotes = ''
      if line[/^>/]
        quotes = line[/^([> ]*>)/, 1].gsub(' ', '')
        line.gsub!(/^[> ]*>/, '')
      end
      line = ' ' + line if line[/^ /]
      if line.length > 78
        line.gsub(/(.{1,#{72 - quotes.length}})(\s+|$)/, "#{quotes}\\1 \n").rstrip
      else
        quotes + line
      end
    end.join("\n")
  end
end
