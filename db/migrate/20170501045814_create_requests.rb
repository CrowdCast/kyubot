class CreateRequests < ActiveRecord::Migration[5.0]
  def change
    create_table :requests do |t|
      t.references :user, index:true
      t.date :days, array:true, null: false, default: []
      t.integer :status, null: false, default:0
      t.string :description
      t.timestamps
    end
    add_foreign_key :requests, :users
  end
end
