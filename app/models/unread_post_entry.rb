class UnreadPostEntry < ActiveRecord::Base
  belongs_to :user
  belongs_to :newsgroup
  belongs_to :post
end
