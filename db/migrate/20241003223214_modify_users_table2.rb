class ModifyUsersTable2 < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :name, :string
  end
end
