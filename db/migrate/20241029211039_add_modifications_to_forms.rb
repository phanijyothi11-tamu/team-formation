class AddModificationsToForms < ActiveRecord::Migration[7.2]
  def change
    add_column :forms, :modifications, :json
  end
end
