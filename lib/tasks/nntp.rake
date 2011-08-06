require 'net/nntp'

namespace :nntp do
  desc "Clear and re-import all posts"
  task :reload => :environment do
    #Post.delete_all
    #Newsgroup.delete_all
    
    Net::NNTP.start('news.csh.rit.edu') do |nntp|
      nntp.list[1].each do |line|
        s = line.split
        if Newsgroup.where(:name => s[0]).exists?
          n = Newsgroup.where(:name => s[0]).first
        else
          n = Newsgroup.create!(:name => s[0], :status => s[3])
        end
        
        puts nntp.group(n.name)[1]
        nntp.listgroup(n.name)[1].each do |num|
          if not Post.where(:newsgroup => n.name, :number => num.to_i).exists?
            head = nntp.head(num)[1].join("\n")
            body = nntp.body(num)[1].join("\n")
            Post.import!(n, num.to_i, head, body)
          end
          print '.'
        end
        puts
      end
    end
  end
end
