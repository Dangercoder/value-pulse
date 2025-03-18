class CreatePropertyAnalyses < ActiveRecord::Migration[8.0]
  def change
    create_table :property_analyses do |t|
      t.string :address
      t.text :additional_info
      t.string :state

      t.timestamps

      t.index :state
      t.index :created_at
    end
  end
end
