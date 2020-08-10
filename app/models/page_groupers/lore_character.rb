class LoreCharacter < ApplicationRecord
  belongs_to :lore
  belongs_to :character, optional: true
  
  belongs_to :user, optional: true
end
