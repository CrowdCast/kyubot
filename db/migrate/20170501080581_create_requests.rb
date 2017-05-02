class CreateRequests < ActiveRecord::Migration[5.0]
  def change
    create_table :requests do |t|
      t.string :description
      t.date :days, array:true, null: false, default: []
      t.integer :status, null: false, default:0
      t.timestamps

      t.references :user, index:true
    end
    add_foreign_key :requests, :users
  end
end
