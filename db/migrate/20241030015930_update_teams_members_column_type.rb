class UpdateTeamsMembersColumnType < ActiveRecord::Migration[7.0]
  def up
    change_column :teams, :members, :json, null: false, default: '{}'
  end

  def down
    change_column :teams, :members, :text
  end
end
