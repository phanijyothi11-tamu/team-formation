class AddPublishedToForms < ActiveRecord::Migration[7.2]
  def change
    add_column :forms, :published, :boolean
  end
end
