class CreateAttributes < ActiveRecord::Migration[7.2]
  def change
    create_table :attributes do |t|
      t.string :name
      t.string :field_type
      t.integer :min_value
      t.integer :max_value
      t.text :options
      t.references :form, null: false, foreign_key: true

      t.timestamps
    end
  end
end
