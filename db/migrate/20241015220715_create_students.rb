class CreateStudents < ActiveRecord::Migration[7.2]
  def change
    create_table :students do |t|
      t.string :uin
      t.string :name
      t.string :email
      t.string :section

      t.timestamps
    end
    add_index :students, :uin, unique: true
  end
end
