class LoreReligion < ApplicationRecord
  belongs_to :lore
  belongs_to :religion, optional: true
  
  belongs_to :user, optional: true
end
