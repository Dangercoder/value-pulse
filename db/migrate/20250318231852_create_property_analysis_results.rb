class CreatePropertyAnalysisResults < ActiveRecord::Migration[8.0]
  def change
    create_table :property_analysis_results do |t|
      t.references :property_analysis, null: false, foreign_key: true
      t.decimal :min_price, precision: 12, scale: 2
      t.decimal :max_price, precision: 12, scale: 2
      t.decimal :estimated_price, precision: 12, scale: 2
      t.string :price_display_text
      t.integer :bedrooms
      t.decimal :bathrooms, precision: 4, scale: 1
      t.integer :square_footage
      t.integer :year_built
      t.string :property_type
      t.string :neighborhood_quality
      t.string :investment_rating
      t.decimal :rental_potential, precision: 6, scale: 2
      t.string :confidence_level
      t.text :key_factors
      t.text :comparable_properties
      t.text :market_trends
      t.jsonb :json_data, default: {}
      t.string :model_used

      t.timestamps

      t.index :estimated_price
      t.index :property_type
      t.index :confidence_level
      t.index :investment_rating
    end
  end
end
