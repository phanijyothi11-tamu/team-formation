class CreateTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :teams do |t|
      t.references :form, null: false, foreign_key: true
      t.string :name
      t.json :members, null: false, default: '{}'
      t.string :section

      t.timestamps
    end
  end
end
