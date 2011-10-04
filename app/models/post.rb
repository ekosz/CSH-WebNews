class Post < ActiveRecord::Base
  belongs_to :newsgroup, :foreign_key => :newsgroup, :primary_key => :name
  has_many :unread_post_entries, :dependent => :destroy
  before_destroy :kill_parent_id
  
  def author_name
    author[/"?(.*?)"? ?<.*>/, 1] || author[/.* \((.*)\)/, 1] || author
  end
  
  def author_email
    author[/"?.*?"? <(.*)>/, 1] || author[/(.*) \(.*\)/, 1] || nil
  end
  
  def author_username
    author_email.split('@')[0] if author_email
  end
  
  def author_is_local?
    !author_email[LOCAL_EMAIL_DOMAIN].nil? if author_email
  end
  
  def quoted_body
    author_name + " wrote:\n\n" +
      body.chomp.sub(/(.*)\n-- \n.*/m, '\\1').
        split("\n").map{ |line| '>' + line }.join("\n") + "\n\n"
  end
  
  def is_crossposted?(quick = false)
    if quick
      headers[/^Newsgroups: (.*)/i, 1].split(',').length > 1
    else
      in_all_newsgroups.length > 1
    end
  end
  
  def is_reparented?
    parent_id != original_parent_id
  end
  
  def is_orphaned?
    is_reparented? and parent_id == ''
  end
  
  def followup_newsgroup
    Newsgroup.find_by_name(headers[/^Followup-To: (.*)/i, 1])
  end
  
  def in_newsgroup(newsgroup)
    newsgroup.posts.find_by_message_id(message_id)
  end
  
  def in_all_newsgroups
    headers[/^Newsgroups: (.*)/i, 1].
      split(',').
      map(&:strip).
      map{ |name| Newsgroup.find_by_name(name) }.
      reject(&:nil?).
      map{ |newsgroup| in_newsgroup(newsgroup) }.
      reject(&:nil?)
  end
  
  def parent
    Post.where(:message_id => parent_id, :newsgroup => newsgroup.name).first
  end
  
  def children
    Post.where(:parent_id => message_id, :newsgroup => newsgroup.name).order('date')
  end
  
  def thread_parent
    Post.where(:message_id => thread_id, :newsgroup => newsgroup.name).first
  end
  
  def all_in_thread
    Post.where(:thread_id => thread_id)
  end
  
  def original_parent_id
    headers[/^References: (.*)/i, 1].to_s.split.map{ |r| r[/<.*>/] }[-1] || ''
  end
  
  def original_parent
    Post.where(:message_id => original_parent_id).first
  end
  
  def authored_by?(user)
    author_name == user.real_name or author_email == user.email
  end
  
  def user_in_thread?(user)
    return true if authored_by?(user)
    return all_in_thread.reduce(false){ |m, post| m || post.authored_by?(user) }
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
    return true if unread_for_user?(user)
    return all_in_thread.reduce(false){ |m, post| m || post.unread_for_user?(user) }
  end
  
  def personal_class_for_user(user)
    case
      when authored_by?(user) then :mine
      when parent && parent.authored_by?(user) then :mine_reply
      when thread_parent.user_in_thread?(user) then :mine_in_thread
    end
  end
  
  def kill_parent_id
    # Sub-optimal, should re-parent to next reference up the chain
    # (but posts getting canceled when they already have replies is rare)
    Post.where(:parent_id => message_id).each do |post|
      post.update_attributes(:parent_id => '', :thread_id => post.message_id, :first_line => post.subject)
    end
  end
  
  def build_cancel_message(user, reason)
    m = "From: #{user.real_name} <#{user.email}>"
    m += "\nSubject: cmsg cancel #{message_id}"
    m += "\nNewsgroups: " + headers[/^Newsgroups: (.*)/i, 1]
    m += "\nControl: cancel #{message_id}"
    m += "\nContent-Type: text/plain; charset=utf-8; format=flowed"
    m += "\nUser-Agent: CSH-WebNews"
    
    m += "\n\nThe following message was canceled by #{user.real_name}:\n"
    [
      headers[/^From: .*/i],
      headers[/^Subject: .*/i],
      headers[/^Date: .*/i],
      headers[/^Newsgroups: .*/i],
      headers[/^Message-ID: .*/i]
    ].each do |header|
      m += "\n  #{header}"
    end
    
    if not reason.blank?
      m += "\n\n" + Post.flowed_encode('The reason given was: ' + reason)
    end
    
    return m
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
    return m
  end
  
  def self.import!(newsgroup, number, headers, body)
    attachments_stripped = false
    headers.gsub!(/\n( |\t)/, ' ')
    headers.encode!('US-ASCII', :invalid => :replace, :undef => :replace)
  
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
    
    body.rstrip!
    body += "\n\n--- Attachments stripped by WebNews ---" if attachments_stripped
    
    date = Time.parse(headers[/^Date: (.*)/i, 1])
    author = headers[/^From: (.*)/i, 1]
    subject = first_line = headers[/^Subject: (.*)/i, 1]
    message_id = headers[/^Message-ID: (.*)/i, 1]
    references = headers[/^References: (.*)/i, 1].to_s.split.map{ |r| r[/<.*>/] }
    
    parent_id = references[-1] || ''
    thread_id = message_id
    possible_thread_id = references[0] || ''
    parent = where(:message_id => parent_id, :newsgroup => newsgroup.name).first
    
    # Note: Doesn't try to fix replies ("Re:") that simply have no References at all
    if parent_id != '' and not parent
      if where(:message_id => parent_id).exists?
        parent_id = ''
      else
        if possible_thread_id != '' and
            where(:message_id => possible_thread_id, :newsgroup => newsgroup.name).exists?
          parent_id = thread_id = possible_thread_id
        else
          possible_thread_parent =
            where('subject = ? and newsgroup = ? and date < ?',
              subject.sub(/Re: /i, ''), newsgroup.name, date).order('date DESC').first ||
            where('subject = ? and newsgroup = ? and date < ?',
              subject, newsgroup.name, date).order('date').first
          
          if possible_thread_parent
            parent_id = thread_id = possible_thread_parent.message_id
          else
            parent_id = ''
          end
        end
      end
    elsif parent # Parent exists and is in the same newsgroup
      thread_id = parent.thread_id
    end
    
    if subject[/^Re:/i] and parent_id != ''
      body.each_line do |line|
        if not (line.blank? or line[/^>/] or line[/(wrote|writes):$/] or
            line[/^In article/] or line[/^On.*\d{4}.*:/] or line[/wrote in message/] or
            line[/news:.*\.\.\.$/] or line[/^\W*snip\W*$/])
          first_line = line.sub(/ +$/, '')
          first_line = first_line.rstrip + '...' if first_line[/\w\n/]
          first_line.rstrip!
          break
        end
      end
    end
    
    create!(:newsgroup => newsgroup,
            :number => number,
            :subject => subject,
            :author => author,
            :date => date,
            :message_id => message_id,
            :parent_id => parent_id,
            :thread_id => thread_id,
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
