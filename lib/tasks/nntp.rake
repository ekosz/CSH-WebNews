require 'net/nntp'

namespace :nntp do
  desc "Clear and re-import all posts"
  task :reload => :environment do
    Post.delete_all
    Newsgroup.delete_all
    
    Net::NNTP.start('news.csh.rit.edu') do |nntp|
      nntp.list[1].each do |line|
        s = line.split
        n = Newsgroup.create!(:name => s[0], :status => s[3])
        puts "\n" + n.name
      end
        
        n = Newsgroup.find_by_name('csh.projects')
        nntp.listgroup('csh.projects')[1].each do |num|
          head = nntp.head(num)[1].join("\n")
          body = nntp.body(num)[1].join("\n")
          Post.create!(:newsgroup => n,
            :number => num.to_i,
            :subject => head[/Subject: (.*)/, 1],
            :author => head[/From: (.*)/, 1],
            :date => DateTime.parse(head[/Date: (.*)/, 1]),
            :message_id => head[/Message-ID: (.*)/, 1],
            :references => head[/References: (.*)/, 1] || '',
            :headers => head,
            :body => body)
          print '.'
        end
      #end
    end
  end
end
