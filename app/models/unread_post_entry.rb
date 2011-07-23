class UnreadPostEntry < ActiveRecord::Base
  belongs_to :user
  belongs_to :post, :foreign_key => [:newsgroup, :number], :primary_key => [:newsgroup, :number]
end
