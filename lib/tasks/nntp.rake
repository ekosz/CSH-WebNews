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
          Post.import!(n, num.to_i, head, body)
          print '.'
        end
        puts
        
        n = Newsgroup.find_by_name('csh.committee.publicrelations')
        nntp.listgroup('csh.committee.publicrelations')[1].each do |num|
          head = nntp.head(num)[1].join("\n")
          body = nntp.body(num)[1].join("\n")
          Post.import!(n, num.to_i, head, body)
          print '.'
        end
        
        puts
      #end
    end
  end
end
