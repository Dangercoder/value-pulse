class AddGooglePlaceAttributesToPropertyAnalysis < ActiveRecord::Migration[8.0]
  def change
    add_column :property_analyses, :place_id, :string
    add_column :property_analyses, :latitude, :float
    add_column :property_analyses, :longitude, :float
  end
end
