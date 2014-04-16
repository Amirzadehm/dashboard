class LevelSourceImage < ActiveRecord::Base
  belongs_to :level_source

  MIN_GOOD_IMAGE_SIZE = 1000 # I just kind of arbitrarily picked this because all the empty images I saw were < 1000 bytes

  def better?(new_image)
    image.size < MIN_GOOD_IMAGE_SIZE &&
      new_image.size > image.size
  end

  def replace_image_if_better(new_image)
    if image.blank? || better?(new_image)
      self.image = new_image
      save
    end
  end
end
