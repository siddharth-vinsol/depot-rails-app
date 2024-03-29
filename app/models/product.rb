class Product < ApplicationRecord
  PERMALINK_REGEX = /\A[a-z0-9-]+\z/i.freeze
  DESCRIPTION_WORDS_REGEX = /[a-z0-9]+/i.freeze
  DEFAULT_TITLE = 'abc'.freeze
  
  belongs_to :category, counter_cache: true

  has_many :ratings, dependent: :destroy
  has_many :line_items, dependent: :restrict_with_error
  has_many :orders, through: :line_items
  has_many :carts, through: :line_items
  has_many_attached :images, dependent: :destroy

  validates :title, :description, :image_url, :price, :discount_price, presence: true
  validates :price, numericality: { greater_than: 0 }, allow_blank: true
  validates :discount_price, numericality: { greater_than: 0 }, allow_blank: true
  validates :price, comparison: { greater_than: :discount_price, message: 'must be greater than discount price' }, allow_blank: true
  validates :title, uniqueness: true
  validates :permalink, uniqueness: { message: "Should be unique", case_sensitive: false }, allow_blank: true
  validates :permalink, format: { with: PERMALINK_REGEX, message: "cannot have special character and no space allowed" }, allow_blank: true
  validates_length_of :words_in_description, in: 5..10, too_short: 'must be more than 5', too_long: 'must be less than 10', allow_blank: true
  validates :words_in_permalink_separated_by_hypen, comparison: { greater_than_or_equal_to: 3 }
  validates :image_url, image_url: true, allow_blank: true
  validates_length_of :images, minimum: 1, maximum: 3, too_short: 'must have atleast one image', too_long: 'cannot have more than 3 images'

  before_validation :assign_default_title, unless: :title?
  before_validation :assign_default_discount, unless: :discount_price?
  after_create_commit :increment_parent_category_products_count, if: -> { category.parent }
  after_destroy_commit :decrement_parent_category_products_count, if: -> { category.parent }
  
  scope :enabled_products, -> { where(enabled: true) }
  scope :taken_products, -> { joins(:line_items).distinct }

  def self.taken_product_titles
    taken_products.pluck(:title)
  end

  private def assign_default_title
    self.title = DEFAULT_TITLE
  end

  private def assign_default_discount
    self.discount_price = price
  end

  private def ensure_not_referenced_by_any_line_item
    unless line_items.empty?
      errors.add(:base, 'Line Items present')
      throw :abort
    end
  end

  private def words_in_description
    description.scan(DESCRIPTION_WORDS_REGEX)
  end

  private def words_in_permalink_separated_by_hypen
    permalink.split('-').length
  end

  private def increment_parent_category_products_count
    category.parent.increment!(:products_count)
  end

  private def decrement_parent_category_products_count
    category.parent.decrement!(:products_count)
  end

  scope :enabled_products, -> { where(enabled: true) }
end
